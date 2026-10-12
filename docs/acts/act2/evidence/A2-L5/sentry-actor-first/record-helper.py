import pathlib,hashlib,json,re,subprocess,sys,datetime,shutil
root=pathlib.Path.cwd();label=sys.argv[1];mode=sys.argv[2];args=sys.argv[3:]
assert re.fullmatch(r"[a-z0-9-]+",label) and mode in ["engine","import"]
dest=root/"docs/acts/act2/evidence/A2-L5"/label
dest.mkdir(parents=True,exist_ok=False);(dest/".gdignore").write_text("")
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
queue=["scripts/acts/act2/dead_london_bait.gd","tests/acts/act2/a2_l5_bait_smoke.gd","project.godot","scripts/dev/dev.py",".cinder/local.json"]
queue += [a for a in args if a.endswith((".gd",".tscn")) and (root/a).is_file()]
seen={}
while queue:
 name=queue.pop()
 if name in seen or not (root/name).is_file():continue
 p=root/name;seen[name]=digest(p);out=dest/"source"/name;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,out)
 if p.suffix in [".gd",".tscn",".tres",".godot",".gdshader",".json",".py"]:
  queue.extend(re.findall(r'res://([^"\s\)]+)',p.read_text(errors="ignore")))
 if (root/(name+".uid")).is_file():queue.append(name+".uid")
raw=root/".cinder"/("a2-l5-"+label+".log")
cmd=["python3","scripts/dev/dev.py",mode]
if mode=="engine":cmd += ["--path",".","--log-file",str(raw),*args]
source={"at":datetime.datetime.now(datetime.timezone.utc).isoformat(),"cwd":str(root),"head":subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip(),"shared_publication":"fc4031324db0ae16e8a7c06e1f6144bcf00e5e27","api_revision":"campaign-shared-38","command":cmd,"files":seen,"source_scope":"Explicit new Sentry actor/ray/actor fixture plus retained native bait fixture/cache and project/dev/local configuration, with recursive literal resources/UIDs. Import may scan additional existing project resources; this subset is not a complete project clone.","test_scope":"New-resource parser/import and isolated Sentry actor API/prospective pose only. No native Scheduler/ray/foot, recognizer, whole-parent, checkpoint, balance or art acceptance."}
(dest/"source.json").write_text(json.dumps(source,indent=2)+"\n")
with (dest/"wrapper.log").open("w") as f:r=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT)
if raw.is_file():shutil.copy2(raw,dest/"raw.log")
logs={"wrapper":(dest/"wrapper.log").read_text(errors="replace")}
if (dest/"raw.log").is_file():logs["raw"]=(dest/"raw.log").read_text(errors="replace")
counts={n:{"script_errors":len(re.findall(r"^SCRIPT ERROR:",log,re.M)),"native_errors":len(re.findall(r"^ERROR:",log,re.M)),"fail_markers":len(re.findall(r"FAIL:",log))} for n,log in logs.items()}
log=logs.get("raw",logs["wrapper"]);lines=[s for s in log.splitlines() if re.search(r"checks|failures|SCRIPT ERROR:|ERROR:|FAIL:",s)]
unchanged=all((root/n).is_file() and digest(root/n)==h for n,h in seen.items())
result={"exit_code":r.returncode,"log_counts":counts,"result_lines":lines,"source_count":len(seen),"sources_unchanged":unchanged,"source_sha256":digest(dest/"source.json"),"wrapper_sha256":digest(dest/"wrapper.log"),"raw_sha256":digest(dest/"raw.log") if (dest/"raw.log").is_file() else None}
(dest/"result.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps({k:v for k,v in result.items() if k!="result_lines"}|{"result_lines":[line[:350] for line in lines[-5:]]}));sys.exit(r.returncode if r.returncode else (1 if not unchanged or any(any(v.values()) for v in counts.values()) else 0))
