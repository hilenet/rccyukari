(function (){
  window.onload = function(){
    var logarea = document.getElementById("log-area");
    var form = document.getElementById("form");
    var send_text = document.getElementById("send_text");
    var ws = new WebSocket("ws://" + window.location.host + "/ws");

    ws.onopen = function() {
      console.log("connection opened");
    }
    ws.onclose = function() { 
      console.log("connection closed");
    }
    ws.onmessage = function(m) {
      var li = document.createElement("li");
      li.textContent = parseJson(m.data);
      logarea.insertBefore(li, logarea.firstChild);
    }
    send_text.onclick = function(){
      send_text.value = ""; 
    }
    form.onsubmit = function(){
      ws.send(send_text.value);
      send_text.value = "";
      return false;
    }

    function parseJson(data) {
      json = JSON.parse(data)
      return json['time']+": "+json['text'];
    }
  }
})();
