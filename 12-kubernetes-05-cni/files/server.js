var http = require('http');

var os = require("os");
var hostname = os.hostname();

var handleRequest = function(request, response) {
  console.log('Получен запрос на URL: ' + request.url);
  response.writeHead(200);
  response.end('Hello World! I am '+hostname+'\r\n');
};
var www = http.createServer(handleRequest);
www.listen(8080);
