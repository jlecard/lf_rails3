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

function getCookie(name) {
    var start = document.cookie.indexOf(name+"=");
    var len = start+name.length+1;
    if ((!start) && (name != document.cookie.substring(0,name.length))) return null;
    if (start == -1) return null;
    var end = document.cookie.indexOf(";",len);
    if (end == -1) end = document.cookie.length;
    return unescape(document.cookie.substring(len,end));
}

function setCookie(name,value,expires,path,domain,secure) {
var today = new Date();
var expires = new Date(today.getTime() + (24 * 60 * 60 * 1000 * 365));
var path = '/';
    document.cookie = name + "=" +value +
        ( (expires) ? ";expires=" + expires.toGMTString() : "") +
        ( (path) ? ";path=" + path : "/") +
        ( (domain) ? ";domain=" + domain : "") +
        ( (secure) ? ";secure" : "");
}

function delCookie(name,value,expires,path,domain,secure) {
var today = new Date();
var expires = new Date(today.getTime() - (24 * 60 * 60 * 1000 * 365));
var path = '/';
    document.cookie = name + "=" +value +
        ( (expires) ? ";expires=" + expires.toGMTString() : "") +
        ( (path) ? ";path=" + path : "/") +
        ( (domain) ? ";domain=" + domain : "") +
        ( (secure) ? ";secure" : "");
}

