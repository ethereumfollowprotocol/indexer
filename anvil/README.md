This is specifically for running anvil in railway

```sh
railway link $RAILWAY_PROJECT_ID anvil --environment='production'
RAILWAY_DOCKERFILE="./Dockerfile" railway up --service='anvil' --environment='production' --detach
```
