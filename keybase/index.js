const express = require('express');
const fs = require('fs')
const app = express()

const data = loadData()

app.use(express.json())

function loadData(){
    return JSON.parse(fs.readFileSync('./data.json'))
}

function saveData(){
    fs.writeFileSync('./data.json', JSON.stringify(data))
}

app.get('/get/:item', (request, response) => {
    let item = request.params.item
    response.type('text/plain')
    response.send(data[item])
    console.log('got ' + item)
})

app.post('/set/:item', (request, response) => {
    let item = request.params.item
    let v = request.body.value
    data[item] = v
    saveData()
    console.log('set ' + item + ' to ' + v)
    response.sendStatus(200)
})

app.listen(34200, () => {
    console.log("App running on port 34200")
})