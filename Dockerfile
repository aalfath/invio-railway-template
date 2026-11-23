# Invio on Railway: the official combined image (backend + frontend), pinned by version and digest.
FROM ghcr.io/kittendevv/invio:v2.5.0@sha256:8e2222c699daaee1e996c0de54cb94a53ad494a295b72bd693ed9fdcd1a5d7b6

# Bake the backend's Deno modules into the image, so a boot never has to download
# them from deno.land / jsr / npm (upstream fetches them on every start).
ENV DENO_DIR=/opt/deno-cache \
    DENO_NO_UPDATE_CHECK=1 \
    DATABASE_PATH=/app/data/invio.db \
    BACKEND_PORT=3000 \
    WEASYPRINT_BIN=/usr/bin/weasyprint
# bcrypt hashes passwords in a Worker loaded at runtime, so cache its worker module too.
RUN cd /app/backend \
 && deno cache --quiet src/app.ts https://deno.land/x/bcrypt@v0.4.1/src/worker.ts \
 && mkdir -p /app/data

COPY start.sh /usr/local/bin/invio-start
RUN chmod 0755 /usr/local/bin/invio-start

EXPOSE 8000
CMD ["/usr/local/bin/invio-start"]
