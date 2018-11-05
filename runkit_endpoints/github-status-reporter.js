const express = require("@runkit/runkit/express-endpoint/1.0.0");
const bodyParser = require('body-parser')
const app = express(exports);
const GitHubApi = require("@octokit/rest");

app.use(bodyParser.json())

app.post("/", (req, res) => {
    const params = req.body

    console.log('START', params)

    if (!process.env.GITHUB_ACCESS_TOKEN) {
        const message = 'please set your GITHUB_ACCESS_TOKEN in the runkit environment variables page'
        const json = JSON.stringify({ success: false, message })
        return res.send(json)
    }

    //console.log(params);

    if (params && params.owner == "apache" && params.body) {
        if (params.repo == "mynewt-core" || params.repo == "mynewt-nimble") {
            return createStatus(params, res);
        }
    }

    const json = JSON.stringify({ success: false, message: 'incorrect params provided' })
    res.send(json)
});

function createStatus(params, res) {
    const gh = new GitHubApi({
        version: "3.0.0"
    });

    gh.authenticate({
        type: "token",
        token: process.env.GITHUB_ACCESS_TOKEN
    });

    const new_params = {
        owner: params.owner,
        repo: params.repo,
        target_url: params.target_url, //FIXME: sanitize
        context: 'continuous-integration/rat-report',
        description: 'RAT Report',
        sha: params.sha,
        state: params.state
    };

    console.log(new_params);

    gh.repos.createStatus(new_params, error => {
        const success = !error
        if (error) console.log(error)
        const message = error && error.message
        const response = { success, message }
        const json = JSON.stringify(response)
        return res.send(json);
    });
}
