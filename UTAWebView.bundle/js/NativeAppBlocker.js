var host=window.location.host;
if (host.indexOf('item.m.jd.com')>=0) {
    var eleApp=document.body.getElementsByTagName('header')[0];
    eleApp=eleApp.getElementsByTagName('div')[0];
    if(eleApp.childNodes[0].getAttribute('id').indexOf(eleApp.getAttribute('id'))==0){eleApp.remove();}
}
else if (host.indexOf('m.jd.com')>=0) {
    var eleApp1=document.getElementById('layout_top').nextElementSibling;
    var eleApp2=document.getElementsByClassName('viewport')[0].previousElementSibling;
    if(eleApp1==eleApp2){eleApp1.remove();}
}
else if (host.indexOf('jd.com')>=0) {
    var ele=document.getElementById('m_common_tip');
    if(undefined!=ele){ele.remove()}
    ele=document.getElementById('index_banner');
    if(undefined!=ele){ele.remove();}
}
else if (host.indexOf('m.taobao.com')>=0) {
    var eles = document.getElementsByClassName('scroll-content');
    if (eles.length==1){
        var ele=eles[0].childNodes[0];
        if(2==ele.childElementCount&&2==ele.getElementsByTagName('a').length){ele.remove();}
    }
    var allDiv=document.getElementsByTagName('div');
    var ele=allDiv[allDiv.length-1];
    if(2==ele.childElementCount&&2==ele.getElementsByTagName('a').length){ele.remove();}
}
else if (host.indexOf('m.intl.taobao.com')>=0) {
    var ele=document.getElementsByClassName('thw-smartbanner')[0];
    if(undefined!=ele){ele.remove();}
}
else if (host.indexOf('m.vip.com')>=0) {
    var ele=document.getElementsByClassName('u-download-bar')[0].parentElement;
    if(undefined!=ele){ele.remove();}
}
else if (host.indexOf('detail.m.tmall.com')>=0) {
    var ele=document.getElementById('detail-base-smart-banner');
    if(ele!=undefined){ele.remove();}
}
else if (host.indexOf('detail.m.tmall.hk')>=0) {
    var ele=document.getElementById('detail-base-smart-banner');
    if(ele!=undefined){ele.remove();}
}
else if (host.indexOf('www.tmall.com')>=0) {
    var ele=document.getElementById('J_BottomSmartBanner');
    if(ele!=undefined){ele.remove();}
}
else if (host.indexOf('m.vancl.com')>=0) {
    var ele=document.getElementById('floatBox');
    if(ele!=undefined){ele.remove();}
}
else if (host.indexOf('m.dangdang.com')>=0) {
    var ele=document.getElementsByClassName('app-download-wrapper')[0].getElementsByClassName('close-app-download')[0];
    if(ele!=undefined && ele.tagName.toLowerCase()=="a"){ele.click();}
}
else if (host.indexOf('t.moonbasa.com')>=0){
    var ele=document.getElementById('header').getElementsByClassName('download_app')[0];
    if(ele!=undefined){ele.remove();}
}
else if (host.indexOf('www.mogujie.com')) {
    var ele=document.getElementsByTagName('iframe')[0];
    if(ele!=undefined){ele.remove();}
}