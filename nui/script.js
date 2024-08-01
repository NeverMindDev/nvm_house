
$(function () {
    function display(bool) {
        if (bool) {
            $("#container").show();
        } else {
            $("#container").hide();
            $("#preview-container").hide();
        }
    }

    document.addEventListener('keydown', function(event){
        if(event.key==="Escape"){
            $.post('http://nvm_house/exit', JSON.stringify({}));
            display(false)
        }
    });

    
    window.addEventListener('message', function(event) {
        if (event.data.type === "adminui") {
            if (event.data.status == true) {
                display(true)
            }
            else {
                display(false)
            }
        } else if (event.data.type === "builderui") {
            if (event.data.status == true) {
                display(true)
                $("#player").hide();
                $("#player2").hide();
                $("#statuschange2").hide();
                $("#statuschange").hide();
            } else {
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
   
    $('#container').on('click', '#close', function () {
        $.post('http://nvm_house/exit', JSON.stringify({}));
        display(false)
    });
})

function GetCoords() {
    $.post('https://nvm_house/coords', JSON.stringify({ type: "house"}))
}

function GetCoordsH() {
    $.post('https://nvm_house/coords', JSON.stringify({ type: "garage"}))
}

function Reset() {
    $('#player').val('');
    $('#money').val('');
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
    $("#preview-container").hide();

    const checked = $('#statuschange').is(':checked');
    const ID = $('#player').val();
    const money = $('#money').val();
    const housex = $('#housex').val();
    const housey = $('#housey').val();
    const housez = $('#housez').val();

    const garagex = $('#garagex').val();
    const garagey = $('#garagey').val();
    const garagez = $('#garagez').val();
    const garageh = $('#garageh').val();

    const interior = $('#interior-select').val();

    $.post('https://nvm_house/datas', JSON.stringify({
        isplayer : checked,
        player: ID,
        money: money,
        house: { x: housex, y: housey, z: housez },
        garage: { x: garagex, y: garagey, z: garagez, h: garageh},
        interior: interior
    }))

    $('#player').val('');
    $('#money').val('');
    $('#housex').val('');
    $('#housey').val('');
    $('#housez').val('');
    $('#garagex').val('');
    $('#garagey').val('');
    $('#garagez').val('');
    $('#garageh').val('');
    $('#interior-select').val('1');
}

function Preview() {
    const interior = $('#interior-select').val();
    const imageurl = `./images/${interior}.jpg`;
    $("#preview-container").show();
    $('#preview-image').attr('src', imageurl).show();
}

function Close() {
    $("#preview-container").hide();
}

function StatusChange() {
    const checked = $('#statuschange').is(':checked');
    if (checked) {
        $("#money").hide();
        $("#player").show();
        $("#money2").hide();
        $("#player2").show();
    } else {
        $("#money").show();
        $("#player").hide();
        $("#money2").show();
        $("#player2").hide();
    }
}