
###################
# BUILD FOR LOCAL DEVELOPMENT
###################
# 1. 기본 이미지 설정
FROM node:18-alpine As development
# 2. 작업 디렉터리 설정
WORKDIR /usr/src/app
# 3. 앱 의존성 파일들 복사
# --chown=node:node 옵션은 파일의 소유권을 node 사용자와 그룹에 할당
COPY --chown=node:node package*.json ./
# 4. 앱 의존성 설치
# npm ci는 package-lock.json을 사용하여 정확한 버전의 패키지를 설치하는 명령어
RUN npm ci
# 5. 앱 소스 코드 복사
COPY --chown=node:node . .
# 이후에는 node 사용자로 전환
USER node

###################
# BUILD FOR PRODUCTION
###################

FROM node:18-alpine As build

WORKDIR /usr/src/app

COPY --chown=node:node package*.json ./

COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules

COPY --chown=node:node . .

RUN npm run build

ENV NODE_ENV production

RUN npm ci --only=production && npm cache clean --force

USER node

###################
# PRODUCTION
###################

FROM node:18-alpine As production

COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/dist ./dist

CMD [ "node", "dist/main.js" ]