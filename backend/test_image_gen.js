import { generateChartImage } from "./src/controllers/services/birthChartImage.js";

const sampleChartData = {
  ascendant: { sign: "Pisces", house: 1 },
  houses: {
    1: { sign: "Aries", planets: [] },
    2: { sign: "Taurus", planets: [] },
    3: { sign: "Gemini", planets: ["Jupiter"] },
    4: { sign: "Cancer", planets: ["Ketu"] },
    5: { sign: "Leo", planets: [] },
    6: { sign: "Virgo", planets: [] },
    7: { sign: "Libra", planets: ["Pluto"] },
    8: { sign: "Scorpio", planets: ["Mars"] },
    9: { sign: "Sagittarius", planets: ["Sun", "Saturn", "Uranus", "Neptune"] },
    10: { sign: "Capricorn", planets: ["Mercury", "Venus", "Rahu"] },
    11: { sign: "Aquarius", planets: ["Moon"] },
    12: { sign: "Pisces", planets: [] }
  }
};

(async () => {
  try {
    const imgPath = await generateChartImage(sampleChartData);
    console.log("Image successfully generated at:", imgPath);
  } catch (error) {
    console.error("Error generating image:", error);
  }
})();
