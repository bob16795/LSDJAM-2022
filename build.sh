rm -rf out/content
cp -r content/ out

nim c -d:release -d:release -d:ssl --threads:on -d:mingw -o:out/main.exe main
nim c -d:release -d:release -d:ssl --threads:on main
