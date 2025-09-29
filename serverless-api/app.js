const express = require('express');
const session = require('express-session');
const { Issuer, generators } = require('openid-client');
const app = express();


app.set('view engine', 'ejs');
app.set('views', __dirname + '/views');
// --- Aquí va la configuración de openid-client ---
let client;
async function initializeClient() {
    const issuer = await Issuer.discover('https://cognito-idp.us-east-1.amazonaws.com/us-east-1_0VcouMoQ8');
    client = new issuer.Client({
        client_id: '555d9ec5lslpogerru5t2oh3hi',
        client_secret: '12els4r0u67o0uqcf6vern8j209si2bvg6ka24psclnqbglk44d5',
        redirect_uris: ['https://d84l1y8p4kdic.cloudfront.net'],
        response_types: ['code']
    });
};
initializeClient().catch(console.error);


const checkAuth = (req, res, next) => {
    req.isAuthenticated = !!req.session.userInfo;
    next();
};

app.use(session({
    secret: 'some secret',
    resave: false,
    saveUninitialized: false
}));

app.get('/', checkAuth, (req, res) => {
    res.render('home', {
        isAuthenticated: req.isAuthenticated,
        userInfo: req.session.userInfo
    });
});

app.get('/login', (req, res) => {
    const nonce = generators.nonce();
    const state = generators.state();
    req.session.nonce = nonce;
    req.session.state = state;
    const authUrl = client.authorizationUrl({
        scope: 'openid email phone',
        state,
        nonce
    });
    res.redirect(authUrl);
});

function getPathFromURL(urlString) {
    try {
        const url = new URL(urlString);
        return url.pathname;
    } catch (error) {
        console.error('Invalid URL:', error);
        return null;
    }
}

app.get(getPathFromURL('https://d84l1y8p4kdic.cloudfront.net'), async (req, res) => {
    try {
        const params = client.callbackParams(req);
        const tokenSet = await client.callback(
            'https://d84l1y8p4kdic.cloudfront.net',
            params,
            {
                nonce: req.session.nonce,
                state: req.session.state
            }
        );
        const userInfo = await client.userinfo(tokenSet.access_token);
        req.session.userInfo = userInfo;
        res.redirect('/');
    } catch (err) {
        console.error('Callback error:', err);
        res.redirect('/');
    }
});

app.get('/logout', (req, res) => {
    req.session.destroy();
    const logoutUrl = `https://<user pool domain>/logout?client_id=555d9ec5lslpogerru5t2oh3hi&logout_uri=https://d84l1y8p4kdic.cloudfront.net`;
    res.redirect(logoutUrl);
});

app.listen(3000, () => {
    console.log('App running on http://localhost:3000');
});