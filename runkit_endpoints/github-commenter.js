const express = require("@runkit/runkit/express-endpoint/1.0.0");
const bodyParser = require('body-parser')
const app = express(exports);
const GitHubApi = require("@octokit/rest");

app.use(bodyParser.json())

app.post("/", (req, res) => {
    const params = req.body

    console.log('START', params)

    if (!process.env.GITHUB_BOT_TOKEN) {
        const message = 'please set your GITHUB_BOT_TOKEN in the runkit environment variables page'
        const json = JSON.stringify({ success: false, message })
        return res.send(json)
    }

    if (params && params.owner == "apache") {
        if (params.repo == "mynewt-core" || params.repo == "mynewt-nimble") {
            if (params.body) {
                return newComment(params, res);
            }
        }
    }

    const json = JSON.stringify({ success: false, message: 'incorrect params provided' })
    res.send(json)
});

function newComment(params, res) {
    const gh = new GitHubApi({
        version: "3.0.0"
    });

    gh.authenticate({
        type: "token",
        token: process.env.GITHUB_BOT_TOKEN
    });

    const new_params = {
        owner: params.owner,
        repo: params.repo,
        number: params.number,
        page: "1",
        per_page: "100", // FIXME
    };

    console.log("GET COMMENTS");

    gh.issues.getComments(new_params, (err, response) => {
        if (err) {
            const message = err.message;
            const response = { err, message };
            const json = JSON.stringify(response);
            return res.send(json);
        }

        //FIXME: the code below only deletes one comment at most,
        //       if multiple comments should be deleted, deleteComment
        //       should be made to receive a list of ids than can be
        //       iterated over recursively...

        const data = response.data;
        console.log("DATA:");
        console.log(data);
        let id = 0;
        let body = null;
        for (const el of data) {
            console.log("ELEMENT");
            console.log(el);
            if (el['body'].includes('<!-- license-bot -->')) {
                id = el['id'];
                body = el['body'];
                break;
            }
        }

        if (id != 0 && body != null) {
            return deleteComment(gh, params, id, res);
        } else {
            return createComment(gh, params, res);
        }
    });
}

function deleteComment(gh, params, id, res) {
    const new_params = {
        owner: params.owner,
        repo: params.repo,
        comment_id: id,
    };

    console.log("DELETE COMMENTS");

    gh.issues.deleteComment(new_params, error => {
        console.log(error)
        if (error) {
            const message = error.message;
            const response = { error, message };
            const json = JSON.stringify(response);
            return res.send(json);
        }
        return createComment(gh, params, res);
    });
}


function createComment(gh, params, res) {
    const new_params = {
        owner: params.owner,
        repo: params.repo,
        number: params.number,
        body: params.body,
    };

    console.log("CREATE COMMENT");

    gh.issues.createComment(new_params, error => {
        const success = !error
        if (error) console.log(error)
        const message = error && error.message
        const response = { success, message }
        const json = JSON.stringify(response)
        return res.send(json);
    });
}
