
$(function () {
    function display(bool) {
        if (bool) {
            $("#container").show();
        } else {
            $("#container").hide();
        }
    }

    document.addEventListener('keydown', function(event){
        if(event.key==="Escape"){
            $.post('http://nvm_house/exit', JSON.stringify({}));
            display(false)
        }
    });

    
    window.addEventListener('message', function(event) {
        if (event.data.type === "ui") {
            if (event.data.status == true) {
                display(true)
            }
            else {
                display(false)
            }
        } else if (event.data.type === "coords" ) {
            if (event.data.status == "house" ) {
                $('#housex').val(event.data.x.toFixed(2));
                $('#housey').val(event.data.y.toFixed(2));
                $('#housez').val(event.data.z.toFixed(2));
            } else if (event.data.status == "garage" ) {
                $('#garagex').val(event.data.x.toFixed(2));
                $('#garagey').val(event.data.y.toFixed(2));
                $('#garagez').val(event.data.z.toFixed(2));
                $('#garageh').val(event.data.h.toFixed(2));
            } 
        }
    })
   
})

function GetCoords() {
    $.post('https://nvm_house/coords', JSON.stringify({ type: "house"}))
}

function GetCoordsH() {
    $.post('https://nvm_house/coords', JSON.stringify({ type: "garage"}))
}

function Reset() {
    $('#player').val('');
    $('#housex').val('');
    $('#housey').val('');
    $('#housez').val('');
    $('#garagex').val('');
    $('#garagey').val('');
    $('#garagez').val('');
    $('#garageh').val('');
    $('#interior-select').val('1');
}

function Finish() {
    $("#container").hide();

    const ID = $('#player').val();
    const housex = $('#housex').val();
    const housey = $('#housey').val();
    const housez = $('#housez').val();

    const garagex = $('#garagex').val();
    const garagey = $('#garagey').val();
    const garagez = $('#garagez').val();
    const garageh = $('#garageh').val();

    const interior = $('#interior-select').val();

    $.post('https://nvm_house/datas', JSON.stringify({ 
        player: ID,
        house: { x: housex, y: housey, z: housez },
        garage: { x: garagex, y: garagey, z: garagez, h: garageh},
        interior: interior
    }))

    $('#player').val('');
    $('#housex').val('');
    $('#housey').val('');
    $('#housez').val('');
    $('#garagex').val('');
    $('#garagey').val('');
    $('#garagez').val('');
    $('#garageh').val('');
    $('#interior-select').val('1');
}