require("dotenv").config();
const Hapi = require("hapi");
const superagent = require("superagent");

const server = Hapi.server({ port: process.env.PORT || 3001 });

server.route({
  method: "GET",
  path: "/engagement",
  handler: async (request, h) => {
    const response = await superagent
      .post("https://app.officevibe.com/api/v2/engagement")
      .set("Authorization", `Bearer ${process.env.OFFICEVIBE_TOKEN}`)
      .send({
        groupNames: request.query.groupNames.split(","),
        dates: request.query.dates.split(",")
      });

    return response.body;
  }
});

async function start() {
  try {
    await server.start();
    console.log(`Server running at: ${server.info.uri}`);
  } catch (err) {
    console.log(err);
  }
}

start();
