_G.require = require;
local futils = require("build.futils");
local concatPath = futils.concatPath;

local buildMD = require("build.buildMD");
local buildHTML = require("build.buildHTML");
local env = require("env")

local fs = require("fs");
local json = require("json");
local prettyPrint = require("pretty-print");
local p = prettyPrint.prettyPrint; _G.p = p;

---폴더 안에서 빌드할수 있는것들을 싹 찾는다
---@param from string 빌드하고 싶은 디렉터리 트리 (path)
---@param to string 결과물을 담고 싶은 디렉터리 트리 (path)
---@param path any 사용하지 마세요 (재귀 전달) - 아이템의 트리를 자식 재귀로 넘겨줌
---@param items table 사용하지 마세요 (재귀 전달) - 빌드 목록을 자식 재귀로 넘겨줌
---@return table
local function scan(from,to,path,items)
    items = items or {}; -- 빌드해야될 목록을 담는곳
    for _,item in pairs(futils.scan(concatPath(from,path))) do -- 받은 path 를 스캔한다
        local name = item.name; -- 아이템 이름
        local this = concatPath(path,name); -- 아이템의 풀 path
        if item.isFolder then -- 만약 폴더면 재귀한다 (inner search)
            scan(from,to,this,items); -- 자기 자신으로 재귀;
        else
            -- 빌드해야될 목록에 푸시한다
            table.insert(items,{
                ext = futils.getExt(this);
                from = concatPath(from,this);
                to = concatPath(to,this);
            });
        end
    end
    return items; -- 빌드해야될 목록을 반환한다
end

local function mkfile(path)
    futils.mkpath(path:match("(.+)/.-"));
end

local buildTypes = {
    ["md"] = function (o)
        local lastFrom = o.from;
        local tindex = o.dat.tmpIndex;
        local newFrom = concatPath(o.dat.tmp,tindex);
        o.dat.tmpIndex = tindex + 1;
        table.insert(o.dat.mdbuilds,{
            from = lastFrom;
            to = newFrom;
        });
        table.insert(o.dat.rebuild,{
            ext = "html";
            from = newFrom;
            to = o.to:sub(1,-4) .. ".html";
        });
    end;
    ["html"] = function (o)
        local this = fs.readFileSync(o.from);
        if not this:match("<!--DO NOT BUILD-->") then
            -- call the html builder (custom html var)
            local thisEnv = {
                from = o.from;
                to = o.to;
            };
            this = buildHTML.build(this,setmetatable(thisEnv,{__index = env,__newindex = env}));
        end
        mkfile(o.to);
        fs.writeFileSync(o.to,this);
    end;
    ["*"] = function (o)
        mkfile(o.to);
        if jit.os == "Windows" then
            os.execute(("copy %s %s > NUL"):format(o.from:gsub("/","\\"),o.to:gsub("/","\\")));
        else
            os.execute(("cp %s %s > /dev/null"):format(o.from,o.to));
        end
    end;
};
local buildTypes_default = buildTypes["*"];
local buildTypes_html = buildTypes["html"];
---받은 테이블 쌍을 빌드한다, 역시나 재귀가 사용되는 함수
---@param items table 재귀할 아이템이 담긴 테이블, from과 to 쌍으로 이룬다
---@param tmp any 빌드에 사용될 템프 폴더
---@param tmpIndex number|nil 사용하지 마세요 (재귀 전달) - 템프파일 아이드를 자식 재귀로 넘겨줌
local function buildItems(items,tmp,root,tmpIndex)
    futils.mkpath(tmp);
    local dat = {
        tmpIndex = tmpIndex or 0;
        tmp = tmp;
        mdbuilds = {};
        rebuild = {};
        root = root;
        sitemap = concatPath(root,"sitemap.json");
    };
    for _,item in pairs(items) do
        local from = item.from;
        local ext = item.ext;
        if not ext then
            ext = futils.getExt(from);
            item.ext = ext;
        end
        local bfn = buildTypes[ext] or buildTypes_default;
        item.dat = dat;
        bfn(item);
    end

    -- build md items into html
    local mdbuilds = dat.mdbuilds;
    if #mdbuilds ~= 0 then
        buildMD.build(mdbuilds);
    end
    local rebuild = dat.rebuild;
    if #rebuild ~= 0 then
        buildItems(rebuild,tmp,dat.tmpIndex);
    end
end

local function cleanupLastBuild(root)
    local path = concatPath(root,"sitemap.json");
    local raw = fs.readFileSync(path);
    if not raw then
        return;
    end

    local last = json.decode(raw);
    if not last then
        return;
    end
    for i,v in pairs(last) do
        os.remove(v);
    end
    fs.writeFileSync(path,"");
end

local last = {};
local arg = args[2];
if arg == "watch" then
    local uv = require("uv");
    for _,path in pairs({
		"src";
	}) do
		local fse = uv.new_fs_event();
		uv.fs_event_start(fse,path,{
			recursive = true;
		},function (err,fname,status)
			if(err) then
				print(err);
			else
                fname = fname:gsub("\\","/");
                local time = os.clock();
                local this = concatPath(path,fname);
                local ltime = last[this];
                if ltime and ltime+1 >= time then return; end
                last[this] = time;

                print("build: ",this);
				buildItems({{
                    ext = futils.getExt(fname);
                    from = this;
                    to = concatPath("docs",fname);
                }},"build/tmp","docs");
			end
		end);
	end
    require("server");
else
    buildItems(scan("src","docs"),"build/tmp","docs");
end
