require("dotenv").config();
const Hapi = require("hapi");
const superagent = require("superagent");

const server = Hapi.server({ port: process.env.PORT || 3001 });

// http://localhost:3001/engagement?groupNames=Tammerforce&dates=2017-12-01,2018-01-01
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

    return h.response(response.body).header("Access-Control-Allow-Origin", "*");
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
