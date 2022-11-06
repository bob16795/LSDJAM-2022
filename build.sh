rm -rf out/content
cp -r content/ out

nim c --app:gui -d:release -d:ssl --threads:on -d:mingw -o:out/main.exe main
nim c --app:gui -d:release -d:ssl --threads:on main
