rm -rf out/content.bin
cp -r content.bin content/debug.json out
cp test.bin out

nim c --app:gui --opt:speed -b:cpp -d:release -d:ssl --threads:on -d:mingw -o:out/main.exe main
nim c --app:gui --opt:speed -b:cpp -d:release -d:ssl --threads:on main
