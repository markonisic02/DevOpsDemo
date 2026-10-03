FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

COPY ["DevOpsDemo/DevOpsDemo.csproj", "DevOpsDemo/"]

RUN dotnet restore "DevOpsDemo/DevOpsDemo.csproj"

COPY . .

WORKDIR "/src/DevOpsDemo"

RUN dotnet publish "DevOpsDemo.csproj" \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false


FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "DevOpsDemo.dll"]