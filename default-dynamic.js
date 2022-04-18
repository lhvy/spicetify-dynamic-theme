function waitForElement(els, func, timeout = 100) {
  const queries = els.map((el) => document.querySelector(el));
  if (queries.every((a) => a)) {
    func(queries);
  } else if (timeout > 0) {
    setTimeout(waitForElement, 300, els, func, --timeout);
  }
}

function getAlbumInfo(uri) {
  return Spicetify.CosmosAsync.get(`https://api.spotify.com/v1/albums/${uri}`);
}

function hexToRgb(hex) {
  var bigint = parseInt(hex.replace("#", ""), 16);
  var r = (bigint >> 16) & 255;
  var g = (bigint >> 8) & 255;
  var b = bigint & 255;
  return [r, g, b];
}

function rgbToHex([r, g, b]) {
  const rgb = (r << 16) | (g << 8) | (b << 0);
  return "#" + (0x1000000 + rgb).toString(16).slice(1);
}

function lightenDarkenColor(h, p) {
  return (
    "#" +
    [1, 3, 5]
      .map((s) => parseInt(h.substr(s, 2), 16))
      .map((c) => parseInt((c * (100 + p)) / 100))
      .map((c) => (c < 255 ? c : 255))
      .map((c) => c.toString(16).padStart(2, "0"))
      .join("")
  );
}

function rgbToHsl([r, g, b]) {
  (r /= 255), (g /= 255), (b /= 255);
  var max = Math.max(r, g, b),
    min = Math.min(r, g, b);
  var h,
    s,
    l = (max + min) / 2;
  if (max == min) {
    h = s = 0; // achromatic
  } else {
    var d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }
    h /= 6;
  }
  return [h, s, l];
}

function hslToRgb([h, s, l]) {
  var r, g, b;
  if (s == 0) {
    r = g = b = l; // achromatic
  } else {
    function hue2rgb(p, q, t) {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    }
    var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    var p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }
  return [r * 255, g * 255, b * 255];
}

function setLightness(hex, lightness) {
  hsl = rgbToHsl(hexToRgb(hex));
  hsl[2] = lightness;
  return rgbToHex(hslToRgb(hsl));
}

let textColor = getComputedStyle(document.documentElement).getPropertyValue(
  "--spice-text"
);
let textColorBg = getComputedStyle(document.documentElement).getPropertyValue(
  "--spice-main"
);

function setRootColor(name, colHex) {
  let root = document.documentElement;
  if (root === null) return;
  root.style.setProperty("--spice-" + name, colHex);
  root.style.setProperty("--spice-rgb-" + name, hexToRgb(colHex).join(","));
}

function toggleDark() {
  // FIXME: This needs to run once at startup.
  textColorBg = "#0A0A0A";
  setRootColor("main", textColorBg);
  setRootColor("sidebar", textColorBg);
  setRootColor("player", textColorBg);
  setRootColor("card", "#040404");
  setRootColor("subtext", "#EAEAEA");
  setRootColor("notification", "#303030");

  updateColors(textColor);
}
toggleDark();

function updateColors(textColHex) {
  if (textColHex == undefined) return registerCoverListener();

  let darkColHex = lightenDarkenColor(textColHex, -20);
  let darkerColHex = lightenDarkenColor(textColHex, -40);
  let buttonBgColHex = setLightness(textColHex, 0.14);
  setRootColor("text", textColHex);
  setRootColor("button", darkerColHex);
  setRootColor("button-active", darkColHex);
  setRootColor("selected-row", darkerColHex);
  setRootColor("tab-active", buttonBgColHex);
  setRootColor("button-disabled", buttonBgColHex);
}

async function songchange() {
  if (!document.querySelector(".main-trackInfo-container"))
    return setTimeout(songchange, 300);

  try {
    // warning popup
    if (Spicetify.Platform.PlatformData.client_version_triple < "1.1.68")
      Spicetify.showNotification(
        `Your version of Spotify ${Spicetify.Platform.PlatformData.client_version_triple}) is un-supported`
      );
  } catch (err) {
    console.error(err);
  }

  let album_uri = Spicetify.Player.data.track.metadata.album_uri;
  let bgImage = Spicetify.Player.data.track.metadata.image_url;
  if (bgImage === undefined) {
    bgImage = "/images/tracklist-row-song-fallback.svg";
    textColor = "#509bf5";
    updateColors(textColor);
  }

  if (album_uri !== undefined && !album_uri.includes("spotify:show")) {
    await getAlbumInfo(album_uri.replace("spotify:album:", ""));
  } else if (Spicetify.Player.data.track.uri.includes("spotify:episode")) {
    // podcast
  } else if (Spicetify.Player.data.track.metadata.is_local == "true") {
    // local file
  } else if (Spicetify.Player.data.track.provider == "ad") {
    // ad
    return;
  } else {
    // When clicking a song from the homepage, songChange is fired with half empty metadata
    // todo: retry only once?
    setTimeout(songchange, 200);
  }

  registerCoverListener();
}

Spicetify.Player.addEventListener("songchange", songchange);

function pickCoverColor(img) {
  if (!img.currentSrc.startsWith("spotify:")) return;
  if (img.complete) {
    textColor = "#509bf5";
    var swatches = new Vibrant(img, 12).swatches();
    cols = ["Vibrant", "LightVibrant", "Muted", "DarkVibrant"];
    for (var col in cols)
      if (swatches[cols[col]]) {
        textColor = swatches[cols[col]].getHex();
        break;
      }
  }
  updateColors(textColor);
}

var coverListener;
function registerCoverListener() {
  const img = document.querySelector(".main-image-image.cover-art-image");
  if (!img) return setTimeout(registerCoverListener, 250); // Check if image exists
  if (!img.complete) return img.addEventListener("load", registerCoverListener); // Check if image is loaded
  pickCoverColor(img);

  if (coverListener != null) {
    coverListener.disconnect();
    coverListener = null;
  }

  coverListener = new MutationObserver((_) => {
    const img = document.querySelector(".main-image-image.cover-art-image");
    if (!img) return registerCoverListener();
    pickCoverColor(img);
  });
  coverListener.observe(img, {
    attributes: true,
    attributeFilter: ["src"],
  });
}
registerCoverListener();
