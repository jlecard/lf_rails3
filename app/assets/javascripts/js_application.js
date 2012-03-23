// LibraryFind - Quality find done better.
// Copyright (C) 2007 Oregon State University
//
// This program is free software; you can redistribute it and/or modify it under 
// the terms of the GNU General Public License as published by the Free Software 
// Foundation; either version 2 of the License, or (at your option) any later 
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT 
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with 
// this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
// Place, Suite 330, Boston, MA 02111-1307 USA
//
// Questions or comments on this program may be addressed to:
//
// LibraryFind
// 121 The Valley Library
// Corvallis OR 97331-4501
//
// http://libraryfind.org

// Place your application-specific JavaScript functions and classes here

function statusCheck(url){
    autoSubmit();
    if ((document.getElementById('stop_polling')) && (document.getElementById('stop_polling') != null) && (document.getElementById('stop_polling').value != null) && (document.getElementById('stop_polling').value != 'undefined') && (document.getElementById('stop_polling').value == 'false')) {
        new Ajax.Updater('searching_feedback', url.unescapeHTML(), {
            asynchronous: true,
            evalScripts: true,
            parameters: 'jobs=' + escape($('jobs').value)
        });
    }
}

function autoSubmit(){
    if (document.getElementById('jobs_remaining')) {
        if (document.getElementById('jobs_remaining').value == '0') {
            forceSubmit();
        }
    }
}

function forceSubmit(){
    clearInterval(intervalId);
    document.getElementById('stop_polling').value = 'true';
    Element.show('processing_results');
    document.getElementById('stopPolling').click();
}

function setFocus(){
    getQueryElement().focus()
}

function spellCorrection(word){

    var query = document.getElementsByName('query[string1]');
    for (var i = 0; i < query.length; i++) {
        if (query[i].type == 'text') {
            query[i].value = word;
        }
    }
    var form = document.getElementById("form_"+idTab);
    
    var forms = document.getElementsByName('search_form');
    for (var i = 0; i < forms.length; i++) {
        if (forms[i].parentNode.id == form.id) {
            forms[i].submit();
        }
    }
    
    return false;
}

function getQueryElement(){
    var query = document.getElementsByName('string1');
    for (var i = 0; i < query.length; i++) {
        if (query[i].type == 'text') {
            return query[i];
        }
    }
}

function showWait(){
    showWait('waitimage');
}

function showWait(name){
    Element.show(name);
    //ie7 hack
    setTimeout("document.getElementById(name).innerHTML = document.getElementById(name).innerHTML", 200);
}

function showWaitEmail(){
    Element.show('wait_email');
    //ie7 hack
    setTimeout("document.getElementById('wait_email').innerHTML = document.getElementById('wait_email').innerHTML", 200);
}

// Function to process GBS info and update the dom.
function ProcessGBSBookInfo(booksInfo){
    for (isbn in booksInfo) {
        var element = document.getElementById(isbn);
        var bookInfo = booksInfo[isbn];
        if (bookInfo) {
            if (bookInfo.preview == "full") {
                element.innerHTML = '<a href="' + bookInfo.preview_url + '" target="_blank"><img src="http://www.google.com/intl/en/googlebooks/images/gbs_preview_sticker1.png" border="0" /></a>';
                obj_parent = element.parentNode;
                obj_parent.style.display = 'inline';
                element.style.display = 'inline';
            }
            else 
                if (bookInfo.preview == 'partial') {
                    element.innerHTML = '<a href="' + bookInfo.preview_url + '" target="_blank"><img src="http://www.google.com/intl/en/googlebooks/images/gbs_preview_sticker1.png" border="0" /></a>';
                    obj_parent = element.parentNode;
                    obj_parent.style.display = 'inline';
                    element.style.display = 'inline';
                }
        }
    }
}

// Function to process OL Books and update the DOM.
function processOLBooks(booksInfo){
    for (isbn in booksInfo) {
        var element = document.getElementById("OL:" + isbn);
        var bookInfo = booksInfo[isbn];
        var image_url = "";
        image_url = bookInfo.thumbnail_url;
        if (image_url != null && image_url != "" && image_url != 'undefined') {
            image_url = image_url.replace("M-S.jpg", "M-M.jpg");
            element.innerHTML = "<img src=\"" + image_url + "\" border=\"0\" style=\"height:142;width=92;\" />";
            obj_parent = element.parentNode;
            obj_parent.style.display = 'inline';
            element.style.display = 'inline';
        }
    }
}

function addTheCover(booksInfo){
    for (i in booksInfo) {
        var element = document.getElementById("OL:" + i);
        var book = booksInfo[i];
        if (book.thumbnail_url != undefined) {
            element.innerHTML = '<img src="' + book.thumbnail_url + '" border=\"0\" style=\"height:142;width=92;\" />';
            obj_parent = element.parentNode;
            obj_parent.style.display = 'inline';
            element.style.display = 'inline';
        }
    }
}

/**
 * Delay for a number of milliseconds
 */
function sleep(delay){
    var start = new Date().getTime();
    while (new Date().getTime() < start + delay) 
        ;
}
