(function (){
  window.onload = function(){
    var logarea = document.getElementById("log-area");
    var form = document.getElementById("form");
    var send_text = document.getElementById("send_text");
    var silent_button = document.getElementById("silent_button");
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
    text_form.onsubmit = function(){
      text = send_text.value
      if(text=="") return;

      msg = {"msg": text}
      
      ws.send(JSON.stringify(msg))
      send_text.value = "";
      return false;
    }
    silent_button.onclick = function(){
      ws.send(JSON.stringify({"silent": true}));
    }

    function parseJson(data) {
      json = JSON.parse(data)
      time = json['time'].replace(/\-/g, "/");
      return time+": "+json['text'];
    }
  }
})();
