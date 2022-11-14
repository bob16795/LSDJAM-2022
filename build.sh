rm -rf out/content.bin
cp -r content.bin content/debug.json out

nim c --app:gui --opt:speed -d:debug -d:ssl --threads:on -d:mingw -o:out/main.exe main
nim c --app:gui --opt:speed -d:debug -d:ssl --threads:on main
