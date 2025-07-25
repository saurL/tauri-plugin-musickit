"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// index.ts
var index_exports = {};
__export(index_exports, {
  MusicKit: () => MusicKit,
  default: () => index_default,
  musicKit: () => musicKit
});
module.exports = __toCommonJS(index_exports);
var import_core = require("@tauri-apps/api/core");
var MusicKit = class {
  constructor() {
    this.eventListeners = /* @__PURE__ */ new Map();
  }
  /**
   * Initialize MusicKit
   */
  async initialize() {
    await (0, import_core.invoke)("plugin:musickit|initialize");
  }
  /**
   * Request authorization to access Apple Music
   */
  async authorize() {
    return await (0, import_core.invoke)("plugin:musickit|authorize");
  }
  /**
   * Unauthorize access to Apple Music
   */
  async unauthorize() {
    return await (0, import_core.invoke)("plugin:musickit|unauthorize");
  }
  /**
   * Get current authorization status
   */
  async getAuthorizationStatus() {
    return await (0, import_core.invoke)("plugin:musickit|getAuthorizationStatus");
  }
  /**
   * Get user token
   */
  async getUserToken() {
    return await (0, import_core.invoke)("plugin:musickit|getUserToken");
  }
  /**
   * Get developer token
   */
  async getDeveloperToken() {
    return await (0, import_core.invoke)("plugin:musickit|getDeveloperToken");
  }
  /**
   * Get storefront information
   */
  async getStorefrontId() {
    return await (0, import_core.invoke)("plugin:musickit|getStorefrontId");
  }
  /**
   * Get current queue
   */
  async getQueue() {
    return await (0, import_core.invoke)("plugin:musickit|getQueue");
  }
  /**
   * Start playback
   */
  async play() {
    await (0, import_core.invoke)("plugin:musickit|play");
  }
  /**
   * Pause playback
   */
  async pause() {
    await (0, import_core.invoke)("plugin:musickit|pause");
  }
  /**
   * Stop playback
   */
  async stop() {
    await (0, import_core.invoke)("plugin:musickit|stop");
  }
  /**
   * Seek to specific time
   */
  async seek(timeInSeconds) {
    await (0, import_core.invoke)("plugin:musickit|seek", { time: timeInSeconds });
  }
  /**
   * Skip to next track
   */
  async next() {
    await (0, import_core.invoke)("plugin:musickit|next");
  }
  /**
   * Skip to previous track
   */
  async previous() {
    await (0, import_core.invoke)("plugin:musickit|previous");
  }
  /**
   * Skip to specific track
   */
  async skipToItem(trackId, startPlaying) {
    await (0, import_core.invoke)("plugin:musickit|skipToItem", { trackId, startPlaying });
  }
  /**
   * Set volume
   */
  async setVolume(volume) {
    await (0, import_core.invoke)("plugin:musickit|setVolume", { volume });
  }
  /**
   * Set the playback queue
   */
  async setQueue(tracks, startPlaying = false) {
    return await (0, import_core.invoke)("plugin:musickit|setQueue", { tracks, startPlaying });
  }
  /**
   * Update queue
   */
  async updateQueue(tracks) {
    return await (0, import_core.invoke)("plugin:musickit|updateQueue", { tracks });
  }
  /**
   * Insert track at position
   */
  async insertTrackAtPosition(track, position) {
    return await (0, import_core.invoke)("plugin:musickit|insertAtPosition", { track, position });
  }
  /**
   * Insert tracks at position
   */
  async insertTracksAtPosition(tracks, position) {
    return await (0, import_core.invoke)("plugin:musickit|insertTracksAtPosition", { tracks, position });
  }
  /**
   * Remove track from queue
   */
  async removeTrackFromQueue(trackId) {
    return await (0, import_core.invoke)("plugin:musickit|removeFromQueue", { trackId });
  }
  /**
   * Insert track next
   */
  async insertTrackNext(track) {
    return await (0, import_core.invoke)("plugin:musickit|insertTrackNext", { track });
  }
  /**
   * Insert track last
   */
  async insertTrackLast(track) {
    return await (0, import_core.invoke)("plugin:musickit|insertTrackLast", { track });
  }
  /**
   * Append tracks to queue
   */
  async appendTracksToQueue(tracks) {
    return await (0, import_core.invoke)("plugin:musickit|appendToQueue", { tracks });
  }
  /**
   * Listen to MusicKit events
   */
  async addEventListener(event, callback) {
    const unlisten = await (0, import_core.addPluginListener)("musickit", event, (e) => {
      callback(e);
    });
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event).push(unlisten);
    return unlisten;
  }
  /**
   * Remove all event listeners
   */
  removeAllEventListeners() {
    this.eventListeners.forEach((listeners) => {
      listeners.forEach((listener) => {
      });
    });
    this.eventListeners.clear();
  }
  /**
   * Check if user has Apple Music subscription
   */
  async hasSubscription() {
    const status = await this.getAuthorizationStatus();
    return status.status === "authorized";
  }
};
var musicKit = new MusicKit();
var index_default = musicKit;
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  MusicKit,
  musicKit
});
//# sourceMappingURL=index.js.map