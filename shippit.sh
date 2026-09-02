rm -rf ./pub-linux
rm -rf ./pub-windows
rm -rf ./pub-mac
rm -rf ./pub-html
dotnet publish ./src/Metaphor.Spectre/Metaphor.Spectre.vbproj -o ./pub-linux -c Release --sc -p:PublishSingleFile=true -r linux-x64
dotnet publish ./src/Metaphor.Spectre/Metaphor.Spectre.vbproj -o ./pub-windows -c Release --sc -p:PublishSingleFile=true -r win-x64
dotnet publish ./src/Metaphor.Spectre/Metaphor.Spectre.vbproj -o ./pub-mac -c Release --sc -p:PublishSingleFile=true -r osx-x64
dotnet publish ./src/Metaphor.Blazor/Metaphor.Blazor.csproj -o ./pub-html -c Release 
rm -f ./pub-linux/*.pdb
rm -f ./pub-windows/*.pdb
rm -f ./pub-mac/*.pdb
rm -f ./pub-html/*.pdb
butler push pub-windows thegrumpygamedev/beneath-the-blue-room:windows
butler push pub-linux thegrumpygamedev/beneath-the-blue-room:linux
butler push pub-mac thegrumpygamedev/beneath-the-blue-room:mac
butler push pub-html/wwwroot thegrumpygamedev/beneath-the-blue-room:html
