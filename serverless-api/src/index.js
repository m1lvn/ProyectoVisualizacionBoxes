// serverless-api/src/index.js
exports.handler = async (event) => {
  const response = {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Hello from Lambda!',
      env: {
        DB_HOST: process.env.DB_HOST,
        DB_NAME: process.env.DB_NAME
      }
    }),
  };
  return response;
};
