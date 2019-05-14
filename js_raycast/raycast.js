var canvas = document.getElementById("gameCanvas");
var mapCanvas = document.getElementById("mapCanvas");
var ctx = canvas.getContext("2d");
var mapCtx = mapCanvas.getContext("2d");

var PI = Math.PI;
var TWO_PI = Math.PI * 2;
var ONE_HALF_PI = Math.PI * 1.5;
var HALF_PI = Math.PI / 2;

var debugRaycast = false;

var game = {
  paused: false,
  fov: pi(0.25),
  res: 1,
  renderDist: 500,
  rays: []
};

var player = {
  x: NaN,
  y: NaN,
  cellX: NaN,
  cellY: NaN,
  rot: NaN,
  roundRot: NaN,
  speed: 1,
  rotSpeed: 0.01,
  w: 10,
  h: 10,
  
  update: function() {
      //input
    if(keys.up) {
      if(!this.checkX(1)) this.x += this.speed * Math.cos(this.rot);
      if(!this.checkY(1)) this.y += this.speed * Math.sin(this.rot);
    }
    if(keys.down) {
      if(!this.checkX(-1)) this.x -= this.speed * Math.cos(this.rot);
      if(!this.checkY(-1)) this.y -= this.speed * Math.sin(this.rot);
    }
    if(keys.right) this.rot += this.rotSpeed;
    if(keys.left) this.rot -= this.rotSpeed;
    
      //rotation
    if(this.rot >= 0) this.roundRot = (this.rot % pi(2));
    else this.roundRot = pi(2) - Math.abs(this.rot % pi(2));
    
      //misc
    this.cellX = Math.floor(this.x / map.cellWidth);
    this.cellY = Math.floor(this.y / map.cellHeight);
  },
  
  checkX: function(dir) {
    return map.check(
      Math.floor((this.x + (this.speed * Math.cos(this.rot)) * dir) / map.cellWidth),
      this.cellY);
  },
  
  checkY: function(dir) {
    return map.check(
    	this.cellX,
      Math.floor((this.y + (this.speed * Math.sin(this.rot)) * dir) / map.cellHeight));
  }
};

var map = {
  data: [
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
[0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
[0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
[0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
[0, 0, 0, 1, 0, 0, 1, 0, 0, 0],
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
[0, 1, 0, 0, 1, 1, 0, 0, 1, 0],
[0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]],
  width: NaN,
  height: NaN,
  cellWidth: NaN,
  cellHeight: NaN,
  
  get: function(x, y) {
    //console.log(x + ", " + y);
    if(x >= 0 && x < map.width && y >= 0 && y < map.height) return map.data[y][x];
    else return -1;
  },
  
  check: function(x, y) {
    //console.log(x + ", " + y);
    if(x < 0 || y < 0 || x > map.width - 1 || y > map.height - 1) return true;
    else return map.data[y >= 0 ? Math.floor(y) : 0][x > 0 ? Math.floor(x) : 0] > 0;
  }
};

//_____ INPUT FUNCTIONS _____//
var key = {
  keys: {},
  
  init: function(keyNames) {
    for(i = 0; i < keyNames.length; i++) {
      this.keys[keyNames[i]] = false;
    }
  },
  
  press: function(key) {
    this.keys[key] = true;
  },
  
  release: function(key) {
    this.keys[key] = false;
  }
};

var keys = {};

document.addEventListener('keydown', function(e) {
  e.preventDefault();
  switch(e.keyCode) {
    case 39:
      key.press("right");
      break;
    case 37:
      key.press("left");
      break;
    case 38:
      key.press("up");
      break;
    case 40:
      key.press("down");
      break;
    case 32:
      key.press("space");
      break;
    case 80:
      game.paused = !game.paused;
      break;
  }
});

document.addEventListener('keyup', function(e) {
  e.preventDefault();
  switch(e.keyCode) {
    case 39:
      key.release("right");
      break;
    case 37:
      key.release("left");
      break;
    case 38:
      key.release("up");
      break;
    case 40:
      key.release("down");
      break;
    case 32:
      key.release("space");
      break;
  }
});

//_____ CANVAS RENDER FUNCTIONS _____//
var c = {
  rect: function(x, y, w, h, c, alpha) {
    if(isNaN(alpha)) ctx.globalAlpha = 1;
    else ctx.globalAlpha = alpha;
    ctx.fillStyle = c;
    ctx.fillRect(x, y, w, h);
  },
  
  line: function(x1, y1, x2, y2, color, thickness, alpha) {
    if(isNaN(alpha)) ctx.globalAlpha = 1;
    else ctx.globalAlpha = alpha;
    ctx.strokeStyle = color;
    ctx.beginPath();
    ctx.lineWidth = thickness || 1;
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.stroke();
  },
  
  text: function(text, x, y, size, c, centered, alpha) {
    if(isNaN(alpha)) ctx.globalAlpha = 1;
    else ctx.globalAlpha = alpha;
    if(centered === true) ctx.textAlign = "center";
    else ctx.textAlign = "left";
    ctx.font = size + "px Arial";
    ctx.fillStyle = c;
    ctx.textAlign = centered;
    ctx.fillText(text, x, y);
  }
};

var mapC = {
  rect: function(x, y, w, h, c, alpha) {
    if(isNaN(alpha)) mapCtx.globalAlpha = 1;
    else mapCtx.globalAlpha = alpha;
    mapCtx.fillStyle = c;
    mapCtx.fillRect(x, y, w, h);
  },
  
  line: function(x1, y1, x2, y2, color, thickness, alpha) {
    if(isNaN(alpha)) mapCtx.globalAlpha = 1;
    else mapCtx.globalAlpha = alpha;
    mapCtx.strokeStyle = color;
    mapCtx.beginPath();
    mapCtx.lineWidth = thickness || 1;
    mapCtx.moveTo(x1, y1);
    mapCtx.lineTo(x2, y2);
    mapCtx.stroke();
  },
  
  text: function(text, x, y, size, c, centered, alpha) {
    if(isNaN(alpha)) mapCtx.globalAlpha = 1;
    else mapCtx.globalAlpha = alpha;
    if(centered === true) mapCtx.textAlign = "center";
    else mapCtx.textAlign = "left";
    mapCtx.font = size + "px Arial";
    mapCtx.fillStyle = c;
    mapCtx.textAlign = centered;
    mapCtx.fillText(text, x, y);
  }
};

//_____ SETUP AND UPDATE FUNCTIONS _____//
function setup() {
  canvas.width = 500;
  canvas.height = 500;
  mapCanvas.width = 500;
  mapCanvas.height = 500;
  
  map.width = map.data[0].length;
  map.height = map.data.length;
  map.cellWidth = mapCanvas.width / map.width;
  map.cellHeight = mapCanvas.height / map.height;
  
  player.x = 50;
  player.y = 50;
  player.rot = 0;
  
  key.init([
    "right",
    "left",
    "up",
    "down",
    "space"
  ]);
  
  window.requestAnimationFrame(update);
}

function update() {
  //___ UPDATE FUNCTIONS ___//
  
  player.update();
  
  //___ INPUT UPDATES ___//
  
  keys = key.keys;
  
  //___ MAP UPDATES ___//
  
  mapCtx.clearRect(0, 0, mapCanvas.width, mapCanvas.height);
  
    //render map
  for(let i = 0; i < map.width; i++) {
    for(let j = 0; j < map.height; j++) {
      if(map.data[i][j] > 0) {
        mapC.rect(
          j * map.cellWidth,
          i * map.cellHeight,
          map.cellWidth,
          map.cellHeight,
          "black");
      }
    }
  }
  
  for(let i = 0; i < map.width; i++) {
  	mapC.line(i * map.cellWidth, 0, i *  map.cellWidth, mapCanvas.height, "grey", 1, 0.5);
  }
  for(let i = 0; i < map.height; i++) {
  	mapC.line(0, i * map.cellHeight, mapCanvas.width, i *  map.cellHeight, "grey", 1, 0.5);
  }
  
    //render player
  mapC.rect(player.x - (player.w / 2), player.y - (player.h / 2), player.w, player.h, "black");
  
  mapC.line(
    player.x,
    player.y,
    player.x + (Math.cos(player.rot) * 25),
    player.y + (Math.sin(player.rot) * 25),
    "blue", 1);
  
  //___ RAYCAST UPDATES ___//
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  game.rays = raycast();
  //debug(game.rays);
  
  for(let i = 0; i < game.rays.length; i++) {
    /*c.rect(
      i * (canvas.width / game.res),
      (canvas.height / 2) - ((game.renderDist - (game.rays[i]))),
      (canvas.width / game.res),
      (game.renderDist - (game.rays[i]) * 2), "red");*/
    c.rect(
    	i * (canvas.width / game.res),
    	(canvas.height / 2) - ((game.renderDist - (game.rays[i])) / 2),
    	(canvas.width / game.res),
    	((game.renderDist - (game.rays[i]))), "red");
  }
  
  
  window.requestAnimationFrame(update);
}

//_____ OTHER FUNCTIONS _____//
function debug(text) {
  document.getElementById("debug").innerHTML = text;
}

function pi(num) {
  return num * Math.PI
}

function rad(num) {
  return num / Math.PI
}

function dist(x1, y1, x2, y2) {
  return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
}

function roundUpTo(num, interval) {
	return interval * Math.ceil(num / interval);
}

function roundDownTo(num, interval) {
	return interval * Math.floor(num / interval);
}

function getCellX(x) {
	return Math.floor(x / map.cellWidth);
}

function getCellY(y) {
	return Math.floor(y / map.cellHeight)
}

function roundRot(rot) {
	if(rot >= 0) return rot % pi(2);
  else return pi(2) - Math.abs(rot % pi(2));
}

function raycast() {
    //angles
  var startAngle = player.rot - (game.fov / 2);
  var endAngle = player.rot + (game.fov / 2);
  var angleChange = game.fov / (game.res - 1);
  var currAngle = startAngle;
    mapC.line(player.x, player.y, player.x + (Math.cos(startAngle) * 45), player.y + (Math.sin(startAngle) * 45), "#999999", 1);
    mapC.line(player.x, player.y, player.x + (Math.cos(endAngle) * 45), player.y + (Math.sin(endAngle) * 45), "#999999", 1);
  
    //data arrays
  var currPos = [player.x, player.y];
  var startPos = [];
  var result = [];
  var xHit = [];
  var yHit = [];
  
  	//directions
	var xDir = (player.roundRot > pi(1.5) || player.roundRot < pi(0.5)) ? 1 : -1;
  var yDir = (player.roundRot > pi(1) && player.roundRot < pi(2)) ? 1 : -1;
  var slopeX = (Math.sin(currAngle) / Math.cos(currAngle)) * xDir;
  var slopeY = Math.cos(currAngle) / Math.sin(currAngle);
  
  	//misc vars
  var cellPercentX = (player.x - (map.cellWidth * player.cellX)) / map.cellWidth;
  var cellPercentY = (player.y - (map.cellHeight * player.cellY)) / map.cellHeight;
  var toNextCellX = map.cellWidth * (xDir > 0 ? (1 - cellPercentX) : cellPercentX);
  var toNextCellY = map.cellHeight * (yDir > 0 ? -cellPercentY : (1 - cellPercentY));
  var hitX;
  var rayDist = 0;
  
  	//raycast
	for(let i = 0; i < game.res; i++) {
		rayDist = 0;
		xDir = (roundRot(currAngle) > pi(1.5) || roundRot(currAngle) < pi(0.5)) ? 1 : -1;
  	yDir = (roundRot(currAngle) > pi(1) && roundRot(currAngle) < pi(2)) ? 1 : -1;
		slopeX = (Math.sin(currAngle) / Math.cos(currAngle)) * xDir;
  	slopeY = Math.cos(currAngle) / Math.sin(currAngle);
  	
  	while(rayDist < game.renderDist) {
	  	cellPercentX = (currPos[0] - (map.cellWidth * getCellX(currPos[0]))) / map.cellWidth;
	  	cellPercentY = (currPos[1] - (map.cellHeight * getCellY(currPos[1]))) / map.cellHeight;
	  	toNextCellX = map.cellWidth * (xDir > 0 ? (1 - cellPercentX) : cellPercentX);
	  	toNextCellY = map.cellHeight * (yDir > 0 ? -cellPercentY : (1 - cellPercentY));
			slopeX = (Math.sin(currAngle) / Math.cos(currAngle)) * xDir;
	  	slopeY = Math.cos(currAngle) / Math.sin(currAngle);
	  	
	  		if(debugRaycast)console.log("CURRPOS: (" + Math.round(currPos[0]) + ", " + Math.round(currPos[1]) + ") = [" + getCellX(currPos[0]) + ", " + getCellY(currPos[1]) + "]");
	  	
			xHit = [Math.round(currPos[0] + (toNextCellX * xDir)), Math.round(currPos[1] + (slopeX * toNextCellX))];
			yHit = [Math.round(currPos[0] + (slopeY * toNextCellY)), Math.round(currPos[1] + (toNextCellY))];
			
			startPos[0] = currPos[0];
			startPos[1] = currPos[1];
			
			if((xHit[1] - currPos[1]) * -yDir <= toNextCellY * -yDir) {
				mapC.line(currPos[0], currPos[1], currPos[0] + (toNextCellX * xDir), currPos[1] + (slopeX * toNextCellX), "#ff80ff", 2);
					if(debugRaycast && xDir > 0)console.log("roundUp " + xHit[0] + " -> " + (roundUpTo(xHit[0], map.cellWidth) + 1));
					else if(debugRaycast) console.log("roundDown " + xHit[0] + " -> " + (roundDownTo(xHit[0], map.cellWidth) - 1));
				xHit[0] = xDir > 0 ? roundUpTo(xHit[0], map.cellWidth) + 1 : roundDownTo(xHit[0], map.cellWidth) - 1;
				mapC.rect(xHit[0]-2, xHit[1]-2, 4, 4, "#cc00cc");
				rayDist += dist(currPos[0], currPos[1], xHit[0], xHit[1]);
				if(debugRaycast)console.log("xDist: " + dist(currPos[0], currPos[1], xHit[0], xHit[1]));
				currPos[0] = xHit[0];
				currPos[1] = xHit[1];
			} else {
				mapC.line(currPos[0], currPos[1], currPos[0] + (slopeY * toNextCellY), currPos[1] + (toNextCellY), "#80ff80", 2);
					if(debugRaycast && yDir < 0)console.log("roundUp " + yHit[1] + " -> " + (roundUpTo(yHit[1], map.cellHeight) + 1));
					else if(debugRaycast) console.log("roundDown " + yHit[1] + " -> " + (roundDownTo(yHit[1], map.cellHeight) - 1));
				yHit[1] = yDir < 0 ? roundUpTo(yHit[1], map.cellHeight) + 1 : roundDownTo(yHit[1], map.cellHeight) - 1;
				mapC.rect(yHit[0]-2, yHit[1]-2, 4, 4, "#00cc00");
				rayDist += dist(currPos[0], currPos[1], yHit[0], yHit[1]);
				if(debugRaycast)console.log("yDist: " + dist(currPos[0], currPos[1], yHit[0], yHit[1]));
				currPos[0] = yHit[0];
				currPos[1] = yHit[1];
			}
			
				if(debugRaycast)console.log("xHit: (" + Math.round(xHit[0]) + ", " + Math.round(xHit[1]) + "), \nyHit: (" + Math.round(yHit[0]) + ", " + Math.round(yHit[1]) + ")");
				if(debugRaycast)console.log("cellPercent: [" + cellPercentX + ", " + cellPercentY + "]");
				if(debugRaycast)console.log("toNextCell: [" + Math.round(toNextCellX) + ", " + Math.round(toNextCellY) + "]");
				if(debugRaycast)console.log("	CHECK: (" + Math.round(currPos[0]) + ", " + Math.round(currPos[1]) + ") = [" + getCellX(currPos[0]) + ", " + getCellY(currPos[1]) + "] = " + map.get(getCellX(currPos[0]), getCellY(currPos[1])) + "\n\n");
				if(debugRaycast)console.log((getCellX(startPos[0]) - xDir) + ", " + (getCellY(startPos[1]) + yDir));
  		
  		
  		if(((currPos[0] > mapCanvas.width || currPos[0] < 0 || currPos[1] > mapCanvas.height || currPos[1] < 0)
  			|| (map.get(getCellX(currPos[0]), getCellY(currPos[1])) != 0))
  			&& (map.get(getCellX(startPos[0]) - xDir, getCellY(startPos[1])) == 0
  			|| map.get(getCellX(startPos[0]), getCellY(startPos[1]) + yDir) == 0)) {
  				result[i] = rayDist * Math.cos(player.rot - currAngle);
  					mapC.rect(currPos[0] - 2.5, currPos[1] - 2.5, 5, 5, "#0000ff");
  				break;
  		}
  	}
  	currAngle += angleChange;
  	currPos[0] = player.x;
  	currPos[1] = player.y;
	}
	if(debugRaycast)console.log(result);
  debugRaycast = false;
  return result;
}

setup();