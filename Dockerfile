FROM danstaken/slight:v0.5.0 as build
WORKDIR /opt/build
COPY . .
RUN slight buildjs -e ./slightjs_engine.wasm -o ./main.wasm ./src/main.js

FROM scratch
COPY --from=build /opt/build/main.wasm ./app.wasm
COPY --from=build /opt/build/slightfile.toml .
COPY --from=build /etc/ssl /etc/ssl