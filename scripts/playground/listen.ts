import postgres from 'postgres'

const db = postgres(process.env.DATABASE_URL, {
  publications: 'global_publication',
  types: {
    bigint: postgres.BigInt
  }
})

// @see https://github.com/porsager/postgres#realtime-subscribe

const { unsubscribe } = await db.subscribe(
  '*',
  (row, { command, relation }) => {
    console.log(row, command, relation)
  },
  () => {
    console.log('// Callback on initial connect and potential reconnects')
  }
)
