$('#creatormenu').fadeOut(0);

window.addEventListener('message', function(event) {
    const action    = event.data.action;
    const shopBoats  = event.data.shopBoats;
    const myBoats = event.data.myBoats;

    if (action === "hide") {$("#creatormenu").fadeOut(1000);};
    if (action === "show") {$("#creatormenu").fadeIn(1000);};

    if (shopBoats) {
        for (const [index, table] of Object.entries(shopBoats)) {
            const boatType = table.boatType;
            if ($(`#page_shop .scroll-container .collapsible #${index}`).length <= 0) {
                $('#page_shop .scroll-container .collapsible').append(`
                    <li id="${index}">
                        <div class="collapsible-header col s12 panel ">
                            <div class="col s12 panel-title">
                                <h6 class="grey-text plus">${boatType}</h6>
                            </div>
                        </div>
                        <div class="collapsible-body item-bg"></div>
                    </li>
                `);
            };
            for (const [model, boatConfig] of Object.entries(table)) {
                if (model != 'boatType') {
                    let modelBoat;
                    const label = boatConfig.label;
                    const cashPrice  = boatConfig.cashPrice;
                    const goldPrice  = boatConfig.goldPrice;
                    $(`#page_shop .scroll-container .collapsible #${index} .collapsible-body`).append(`
                        <div id="${model}" class="col s12 panel-shop item">
                            <div class="col s6 panel-col item">
                                <h6 class="grey-text-shop title">${label}</h6>
                            </div>          
                            <div class="buy-buttons">
                                <button class="btn-small"  onclick="BuyBoat('${model}', ${cashPrice}, true)">
                                    <img src="img/money.png"><span>${cashPrice}</span>
                                </button>                                  
                                <button class="btn-small right-btn"  onclick="BuyBoat('${model}', ${goldPrice}, false)">                                                
                                    <img src="img/gold.png"><span>${goldPrice}</span>
                                </button>                                          
                            </div>
                        </div>
                    `);
                    $(`#page_shop .scroll-container .collapsible #${index} .collapsible-body #${model}`).hover(function() {                       
                        $(this).click(function() {                        
                            $(modelBoat).addClass("selected");
                            $('.selected').removeClass("selected"); 
                            modelBoat = $(this).attr('id');                       
                            $(this).addClass('selected');
                            $.post('http://oss_boats/LoadBoat', JSON.stringify({BoatModel: $(this).attr('id')}));
                        });                       
                    }, function() {});
                };
            };
        };
        const location  = event.data.location;
        document.getElementById('shop_name').innerHTML = location;
    };
    if (myBoats) {
        $('#page_myboats .scroll-container .collapsible').html('');
        $('.collapsible').collapsible();
        for (const [_, table] of Object.entries(MyBoats)) {
            const boatName = table.name;
            const boatId = table.id;
            const boatModel = table.model;
            $('#page_myboats .scroll-container .collapsible').append(`
                <li>
                    <div id="${boatId}" class="collapsible-header col s12 panel">
                        <div class="col s12 panel-title">
                            <h6 class="grey-text plus">${boatName}</h6>
                        </div>
                    </div>
                    <div class="collapsible-body col s12 panel-myboat item">
                        <button class="col s4 panel-col item-myboat" onclick="Rename(${boatId})">Rename</button>
                        <button class="col s4 panel-col item-myboat" onclick="Launch(${boatId}, '${boatModel}', '${boatName}')">Launch</button>
                        <button class="col s4 panel-col item-myboat" onclick="Sell(${boatId}, '${boatName}')">Sell</button>
                    </div>
                </li>
            `);
            $(`#page_myboats .scroll-container .collapsible #${boatId}`).hover(function() {  
                $(this).click(function() {
                    $.post('http://oss_boats/LoadMyBoat', JSON.stringify({ BoatId: boatId, BoatModel: boatModel}));
                });                         
            }, function() {});
        };
    };
});

function BuyBoat(modelB, price, isCash) {
    if (isCash) {        
        $.post('http://oss_boats/BuyBoat', JSON.stringify({ ModelB: modelB, Cash: price, IsCash: isCash }));
    } else {
        $.post('http://oss_boats/BuyBoat', JSON.stringify({ ModelB: modelB, Gold: price, IsCash: isCash }));
    };
};

function Rename(boatId) {
    $.post('http://oss_boats/RenameBoat', JSON.stringify({BoatId: boatId}));
}

function Launch(boatId, boatModel, boatName) {    
    $.post('http://oss_boats/LaunchBoat', JSON.stringify({ BoatId: boatId, BoatModel: boatModel, BoatName: boatName }));
};

function Sell(boatId, boatName) {    
    $.post('http://oss_boats/SellBoat', JSON.stringify({ BoatId: boatId,  BoatName: boatName}));
};

function Rotate(direction) {
    let rotateBoat = direction;
    $.post('http://oss_boats/Rotate', JSON.stringify({ RotateBoat: rotateBoat }));
};

function CloseMenu() {
    $.post('http://oss_boats/CloseMenu');
    ResetMenu()
};

let currentPage = 'page_myboats';
function ResetMenu() {
    $(`#${currentPage}`).hide();
    currentPage = 'page_myboats';
    $('#page_myboats').show();
    $('.menu-selectb.active').removeClass('active');
    $('#button-myboats.menu-selectb').addClass('active');
};

$('.menu-selectb').on('click', function() {
    $(`#${currentPage}`).hide();
    currentPage = $(this).data('target');
    $(`#${currentPage}`).show();
    $('.menu-selectb.active').removeClass('active');
    $(this).addClass('active');
});
