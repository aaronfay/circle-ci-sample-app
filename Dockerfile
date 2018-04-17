
from node:8

ADD . .
EXPOSE 3000

ENTRYPOINT ["node", "server.js"]
