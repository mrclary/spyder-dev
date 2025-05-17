help([[
No help available

]])
whatis("Version: 0.1.0")
whatis("Keywords: Spyder, Utility")
whatis("Description: Spyder specific environment variables")

family("context")
depends_on_any("miniforge", "miniconda", "anaconda", "micromamba", "pyenv")

-- Directory of this script
spydev = myFileName():sub(1, myFileName():find(myModuleFullName()..".lua", 1, true)-2)
spyide = splitFileName(spydev)
spyrepo = pathJoin(spyide, 'spyder')

setenv("SPYDEV", spydev)
setenv("SPYREPO", spyrepo)
set_alias("spy-build-installers", pathJoin(spydev, "spy-build-installers.sh"))
set_alias("spy-clone-subrepo", pathJoin(spydev, "spy-clone-subrepo.sh"))
set_alias("spy-env", pathJoin(spydev, "spy-env.sh"))
set_alias("spy-menuinst", pathJoin(spydev, "spy-menuinst.sh"))
set_alias("spy-update-conda-app", pathJoin(spydev, "spy-update-conda-app.sh"))
set_alias("spy-run-dev", "conda run --live-stream -n spy-dev spyder")

if io.popen("echo $OSTYPE"):read():find("darwin") then
  set_alias("spy-run-app-term", pathJoin(os.getenv("HOME"), "/Applications/Spyder\\ 6.app/Contents/MacOS/spyder-6"))
  set_alias("spy-run-app", "open -a " ..pathJoin(os.getenv("HOME"), "/Applications/Spyder\\ 6.app") .." --args")
end
