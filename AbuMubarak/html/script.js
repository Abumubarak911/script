// script.js لسكربت CinemaPad

const ipadContainer = document.getElementById("ipad-container");
const mediaUrlInput = document.getElementById("media-url");
const playBtn = document.getElementById("play-btn");
const stopBtn = document.getElementById("stop-btn");
const pauseResumeBtn = document.getElementById("pause-resume-btn");
const volumeSlider = document.getElementById("volume-slider");
const muteBtn = document.getElementById("mute-btn");
const closeBtn = document.getElementById("close-btn");
const statusMessageDiv = document.getElementById("status-message");
const globalSoundRadio = document.getElementById("global-sound");
const spatialSoundRadio = document.getElementById("spatial-sound");
const savedLinksList = document.getElementById("saved-links-list");
const saveLinkBtn = document.getElementById("save-link-btn");

let isMuted = false;
let lastVolume = 0.5; // لتخزين آخر مستوى صوت قبل الكتم
let isPaused = false; // لتتبع حالة الإيقاف المؤقت

// وظيفة لعرض رسائل الحالة
function showStatusMessage(message, type = "error") {
    statusMessageDiv.textContent = message;
    statusMessageDiv.className = `status-message ${type}`;
    setTimeout(() => {
        statusMessageDiv.textContent = "";
        statusMessageDiv.className = "status-message";
    }, 5000); // إخفاء الرسالة بعد 5 ثوانٍ
}

// وظيفة للتحقق من صحة رابط YouTube أو رابط صوتي مباشر
function isValidMediaUrl(url) {
    // تعبير منتظم للتحقق من روابط YouTube
    const youtubeRegex = /^(https?://)?(www\.)?(youtube\.com|youtu\.be)/;
    // تعبير منتظم للتحقق من روابط صوتية مباشرة (mp3, wav, ogg, flac, aac, wma, m4a)(\?.*)?$/i;
    const audioRegex = /\.(mp3|wav|ogg|flac|aac|wma|m4a)(\?.*)?$/i; // تم إصلاح هذا السطر

    return youtubeRegex.test(url) || audioRegex.test(url);
}

// وظيفة لتحميل الروابط المحفوظة من Local Storage
function loadSavedLinks() {
    const links = JSON.parse(localStorage.getItem("cinemapad_saved_links")) || [];
    savedLinksList.innerHTML = ""; // مسح القائمة الحالية
    links.forEach((link, index) => {
        const listItem = document.createElement("li");
        const linkText = document.createElement("span");
        linkText.textContent = link;
        linkText.title = link; // عرض الرابط كاملاً عند التحويم
        linkText.addEventListener("click", () => {
            mediaUrlInput.value = link;
            playBtn.click(); // تشغيل الرابط عند النقر عليه
        });

        const deleteButton = document.createElement("button");
        deleteButton.textContent = "حذف";
        deleteButton.addEventListener("click", () => {
            deleteSavedLink(index);
        });

        listItem.appendChild(linkText);
        listItem.appendChild(deleteButton);
        savedLinksList.appendChild(listItem);
    });
}

// وظيفة لحفظ رابط جديد في Local Storage
function saveLink(url) {
    let links = JSON.parse(localStorage.getItem("cinemapad_saved_links")) || [];
    if (!links.includes(url)) {
        links.push(url);
        localStorage.setItem("cinemapad_saved_links", JSON.stringify(links));
        loadSavedLinks(); // إعادة تحميل القائمة بعد الحفظ
        showStatusMessage("تم حفظ الرابط بنجاح.", "success");
    } else {
        showStatusMessage("الرابط موجود بالفعل.", "info");
    }
}

// وظيفة لحذف رابط من Local Storage
function deleteSavedLink(index) {
    let links = JSON.parse(localStorage.getItem("cinemapad_saved_links")) || [];
    links.splice(index, 1);
    localStorage.setItem("cinemapad_saved_links", JSON.stringify(links));
    loadSavedLinks(); // إعادة تحميل القائمة بعد الحذف
    showStatusMessage("تم حذف الرابط بنجاح.", "success");
}

// استقبال الرسائل من جانب العميل (client.lua)
window.addEventListener("message", function(event) {
    const data = event.data;
    if (data.type === "ui") {
        if (data.status) {
            ipadContainer.classList.remove("hidden");
            setTimeout(() => {
                ipadContainer.classList.add("show");
            }, 10); // تأخير بسيط للسماح بتطبيق العرض قبل الرسوم المتحركة
            loadSavedLinks(); // تحميل الروابط المحفوظة عند فتح الواجهة
        } else {
            ipadContainer.classList.remove("show");
            setTimeout(() => {
                ipadContainer.classList.add("hidden");
            }, 300); // تأخير لمطابقة مدة الانتقال في CSS
        }
    } else if (data.type === "status") {
        showStatusMessage(data.message, data.statusType);
    }
});

// إغلاق الواجهة عند الضغط على زر الإغلاق
closeBtn.addEventListener("click", function() {
    ipadContainer.classList.add("hidden");
    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({}),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// تشغيل الصوت
playBtn.addEventListener("click", function() {
    const url = mediaUrlInput.value;
    const soundRange = document.querySelector("input[name=\"sound-range\"]:checked").value;

    if (!url) {
        showStatusMessage("الرجاء إدخال رابط.", "error");
        return;
    }

    if (!isValidMediaUrl(url)) {
        showStatusMessage("الرابط المدخل غير صالح. الرجاء إدخال رابط YouTube أو رابط صوتي مباشر.", "error");
        return;
    }

    showStatusMessage("جاري التشغيل...", "loading");
    fetch(`https://${GetParentResourceName()}/play`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({ url: url, soundRange: soundRange }),
    }).then(resp => resp.json()).then(resp => {
        if (resp.success) {
            showStatusMessage("تم التشغيل بنجاح.", "success");
            isPaused = false; // إعادة تعيين حالة الإيقاف المؤقت عند التشغيل
            pauseResumeBtn.textContent = "إيقاف مؤقت";
        } else {
            showStatusMessage(resp.message || "حدث خطأ أثناء التشغيل.", "error");
        }
    }).catch(error => {
        console.error("Error playing sound:", error);
        showStatusMessage("حدث خطأ في الاتصال بالخادم.", "error");
    });
});

// إيقاف الصوت
stopBtn.addEventListener("click", function() {
    fetch(`https://${GetParentResourceName()}/stop`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({}),
    }).then(resp => resp.json()).then(resp => {
        if (resp.success) {
            showStatusMessage("تم إيقاف التشغيل.", "success");
            isPaused = false; // إعادة تعيين حالة الإيقاف المؤقت عند الإيقاف
            pauseResumeBtn.textContent = "إيقاف مؤقت";
        } else {
            showStatusMessage(resp.message || "حدث خطأ أثناء الإيقاف.", "error");
        }
    }).catch(error => {
        console.error("Error stopping sound:", error);
        showStatusMessage("حدث خطأ في الاتصال بالخادم.", "error");
    });
});

// إيقاف مؤقت/استئناف الصوت
pauseResumeBtn.addEventListener("click", function() {
    if (isPaused) {
        // استئناف
        fetch(`https://${GetParentResourceName()}/resume`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({}),
        }).then(resp => resp.json()).then(resp => {
            if (resp.success) {
                isPaused = false;
                pauseResumeBtn.textContent = "إيقاف مؤقت";
                showStatusMessage("تم استئناف التشغيل.", "success");
            } else {
                showStatusMessage(resp.message || "فشل استئناف التشغيل.", "error");
            }
        }).catch(error => {
            console.error("Error resuming sound:", error);
            showStatusMessage("حدث خطأ في الاتصال بالخادم.", "error");
        });
    } else {
        // إيقاف مؤقت
        fetch(`https://${GetParentResourceName()}/pause`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({}),
        }).then(resp => resp.json()).then(resp => {
            if (resp.success) {
                isPaused = true;
                pauseResumeBtn.textContent = "استئناف";
                showStatusMessage("تم إيقاف التشغيل مؤقتًا.", "success");
            } else {
                showStatusMessage(resp.message || "فشل إيقاف التشغيل مؤقتًا.", "error");
            }
        }).catch(error => {
            console.error("Error pausing sound:", error);
            showStatusMessage("حدث خطأ في الاتصال بالخادم.", "error");
        });
    }
});

// التحكم في مستوى الصوت
volumeSlider.addEventListener("input", function() {
    const volume = parseFloat(volumeSlider.value);
    lastVolume = volume; // تحديث آخر مستوى صوت
    if (isMuted && volume > 0) {
        isMuted = false;
        muteBtn.textContent = "كتم";
    }
    fetch(`https://${GetParentResourceName()}/volume`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({ volume: volume }),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// كتم/إلغاء كتم الصوت
muteBtn.addEventListener("click", function() {
    if (isMuted) {
        // إلغاء الكتم
        volumeSlider.value = lastVolume; // استعادة آخر مستوى صوت
        isMuted = false;
        muteBtn.textContent = "كتم";
    } else {
        // كتم الصوت
        lastVolume = parseFloat(volumeSlider.value); // حفظ مستوى الصوت الحالي
        volumeSlider.value = 0; // تعيين مستوى الصوت إلى صفر
        isMuted = true;
        muteBtn.textContent = "إلغاء الكتم";
    }
    // إرسال مستوى الصوت الجديد (0 أو lastVolume) إلى العميل
    fetch(`https://${GetParentResourceName()}/volume`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify({ volume: parseFloat(volumeSlider.value) }),
    }).then(resp => resp.json()).then(resp => console.log(resp));
});

// حفظ الرابط الحالي
saveLinkBtn.addEventListener("click", function() {
    const url = mediaUrlInput.value;
    if (url && isValidMediaUrl(url)) {
        saveLink(url);
    } else {
        showStatusMessage("الرجاء إدخال رابط صالح لحفظه.", "error");
    }
});

// تحديث الوقت في الواجهة (مثال بسيط)
function updateTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, "0");
    const minutes = now.getMinutes().toString().padStart(2, "0");
    document.querySelector(".time").textContent = `${hours}:${minutes}`;
}
setInterval(updateTime, 1000); // تحديث كل ثانية
updateTime(); // تحديث فوري عند التحميل


