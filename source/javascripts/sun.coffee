A = 23.45;
B = -0.860;
C = 0.01532;
D = 4.40;

var getTilt = function(time) {
    return A * Math.sin(0.000986301369 * time)
}

for(var i = 0; i < 365; ++i) {
    console.log(i + ": " + getTilt(354 + i).toString());
}
A = 23.45;
B = -0.860;
C = 0.01532;
D = 4.40;

var getTilt = function(time) {
    return A * Math.sin(0.000986301369 * time)
}

for(var i = 0; i < 365; ++i) {
    console.log(i + ": " + getTilt(354 + i).toString());
}