#!/usr/bin/env node

const https = require('https');
const USD = "USD";
const AMD = "AMD";
const RUB = "RUB";
const BR = "-".repeat(10);
const LONG_AGO = 7;
const YESTERDAY = 1;
const TODAY = 0;

// call history api to get currencies data for a given date
const histRate = ((from, date) => {
    return new Promise((resolve, reject) => {
        https.get(`https://api.exchangerate.host/${date}?base=${from}`, (resp) => {
            let data = '';
            resp.on('data', (chunk) => {
                data += chunk;
            });
            resp.on('end', () => {
                resolve(JSON.parse(data));
            });
        }).on('error', reject);
    });
});

// return a string representing the current date minus number of days (0 - for today, 1 - for yesterday)
const date = ((minusDays) => {
    let date = new Date();
    date.setDate(date.getDate() - minusDays);
    return date.toISOString().split('T')[0];
})

// print data structure containing currencies rates data
const print = ((rates) => {
    let heading = 'CURRENCY';
    let usd_amd = `${USD} / ${AMD}`;
    let usd_rub = `${USD} / ${RUB}`;
    let rub_amd = `${RUB} / ${AMD}`;
    let br = BR;
    let decimals = 2;
    let pad = 7;
    for (const [date, rate] of Object.entries(rates)) {
        heading += `\t${date}`;
        br += `\t${BR}`
        usd_amd += `\t${rate[USD][AMD].toFixed(decimals).padStart(pad, ' ')}\t`;
        usd_rub += `\t${rate[USD][RUB].toFixed(decimals).padStart(pad, ' ')}\t`;
        rub_amd += `\t${rate[RUB][AMD].toFixed(decimals).padStart(pad, ' ')}\t`;
    }
    console.log(heading);
    console.log(br);
    console.log(usd_amd);
    console.log(usd_rub);
    console.log(rub_amd);
})

// read response from api to a data structure
const read = ((saveTo, data, currencies) => {
    let date = data.date;
    let base = data.base;
    let rates = data.rates;
    saveTo[date] = saveTo[date] || {};
    saveTo[date][base] = {};
    currencies.forEach(cur => {
        saveTo[date][base][cur] = rates[cur];
    })
})

// data structure to save currencies data to
rates = {};

// the chain of calls: go to api -> read reponse to data structure -> repeat for different date and currency -> print all to console
histRate(USD, date(TODAY))
    .then((res) => {
        read(rates, res, [AMD, RUB]);
        return histRate(RUB, date(TODAY));
    })
    .then((res) => {
        read(rates, res, [AMD]);
        return histRate(USD, date(YESTERDAY));
    })
    .then((res) => {
        read(rates, res, [AMD, RUB]);
        return histRate(RUB, date(YESTERDAY));
    })
    .then((res) => {
        read(rates, res, [AMD]);
        return histRate(USD, date(LONG_AGO));
    })
    .then((res) => {
        read(rates, res, [AMD, RUB]);
        return histRate(RUB, date(LONG_AGO));
    })
    .then((res) => {
        read(rates, res, [AMD]);
    })
    .then(() => {
        print(rates);
    })
