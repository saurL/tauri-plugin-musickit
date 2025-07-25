import { invoke, addPluginListener } from '@tauri-apps/api/core';
import type { PluginListener } from '@tauri-apps/api/core';
import type {
  MusicKitTrack,
  AuthorizationResponse,
  UnauthorizeResponse,
  AuthorizationStatusResponse,
  QueueResponse,
  QueueOperationResponse,
  MusicKitEventMap
} from './types';

export * from './types';

export class MusicKit {
  private eventListeners: Map<string, PluginListener[]> = new Map();

  /**
   * Initialize MusicKit
   */
  async initialize(): Promise<void> {
    await invoke('plugin:musickit|initialize');
  }

  /**
   * Request authorization to access Apple Music
   */
  async authorize(): Promise<AuthorizationResponse> {
    return await invoke('plugin:musickit|authorize');
  }

  /**
   * Unauthorize access to Apple Music
   */
  async unauthorize(): Promise<UnauthorizeResponse> {
    return await invoke('plugin:musickit|unauthorize');
  }

  /**
   * Get current authorization status
   */
  async getAuthorizationStatus(): Promise<AuthorizationStatusResponse> {
    return await invoke('plugin:musickit|getAuthorizationStatus');
  }

  /**
   * Get user token
   */
  async getUserToken(): Promise<string | null> {
    return await invoke('plugin:musickit|getUserToken');
  }

  /**
   * Get developer token
   */
  async getDeveloperToken(): Promise<string | null> {
    return await invoke('plugin:musickit|getDeveloperToken');
  }

  /**
   * Set developer token
   */
  async setDeveloperToken(token: string): Promise<void> {
    await invoke('plugin:musickit|setDeveloperToken', { token });
  }

  /**
   * Set user token
   */
  async setUserToken(token: string): Promise<void> {
    await invoke('plugin:musickit|setUserToken', { token });
  }

  /**
   * Get storefront information
   */
  async getStorefrontId(): Promise<string | null> {
    return await invoke('plugin:musickit|getStorefrontId');
  }

  /**
   * Get current queue
   */
  async getQueue(): Promise<QueueResponse> {
    return await invoke('plugin:musickit|getQueue');
  }

  /**
   * Start playback
   */
  async play(): Promise<void> {
    await invoke('plugin:musickit|play');
  }

  /**
   * Pause playback
   */
  async pause(): Promise<void> {
    await invoke('plugin:musickit|pause');
  }

  /**
   * Stop playback
   */
  async stop(): Promise<void> {
    await invoke('plugin:musickit|stop');
  }

  /**
   * Seek to specific time
   */
  async seek(timeInSeconds: number): Promise<void> {
    await invoke('plugin:musickit|seek', { time: timeInSeconds });
  }

  /**
   * Skip to next track
   */
  async next(): Promise<void> {
    await invoke('plugin:musickit|next');
  }

  /**
   * Skip to previous track
   */
  async previous(): Promise<void> {
    await invoke('plugin:musickit|previous');
  }

  /**
   * Skip to specific track
   */
  async skipToItem(trackId: string, startPlaying: boolean): Promise<void> {
    await invoke('plugin:musickit|skipToItem', { trackId, startPlaying });
  }

  /**
   * Set volume
   */
  async setVolume(volume: number): Promise<void> {
    await invoke('plugin:musickit|setVolume', { volume });
  }

  /**
   * Set the playback queue
   */
  async setQueue(tracks: MusicKitTrack[], startPlaying: boolean = false, startPosition: number = 0): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|setQueue', { tracks, startPlaying, startPosition });
  }

  /**
   * Update queue
   */
  async updateQueue(tracks: MusicKitTrack[]): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|updateQueue', { tracks });
  }

  /**
   * Insert track at position
   */
  async insertTrackAtPosition(track: MusicKitTrack, position: number): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|insertTrackAtPosition', { track, position });
  }

  /**
   * Insert tracks at position
   */
  async insertTracksAtPosition(tracks: MusicKitTrack[], position: number): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|insertTracksAtPosition', { tracks, position });
  }

  /**
   * Remove track from queue
   */
  async removeTrackFromQueue(trackId: string): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|removeTrackFromQueue', { trackId });
  }

  /**
   * Insert track next
   */
  async insertTrackNext(track: MusicKitTrack): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|insertTrackNext', { track });
  }

  /**
   * Insert track last
   */
  async insertTrackLast(track: MusicKitTrack): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|insertTrackLast', { track });
  }

  /**
   * Append tracks to queue
   */
  async appendTracksToQueue(tracks: MusicKitTrack[]): Promise<QueueOperationResponse> {
    return await invoke('plugin:musickit|appendTracksToQueue', { tracks });
  }

  /**
   * Listen to MusicKit events
   */
  async addEventListener<K extends keyof MusicKitEventMap>(
    event: K,
    callback: (payload: MusicKitEventMap[K]) => void
  ): Promise<PluginListener> {
    const unlisten = await addPluginListener('musickit', event, (e) => {
      callback(e as MusicKitEventMap[K]);
    });

    // Store the unlisten function for cleanup
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event)!.push(unlisten);

    return unlisten;
  }

  /**
   * Remove all event listeners
   */
  removeAllEventListeners(): void {
    this.eventListeners.forEach((listeners) => {
      listeners.forEach((listener) => {
        // PluginListener is a function that can be called to remove the listener
        try {
          (listener as any)();
        } catch (error) {
          // Ignore errors when removing listeners
        }
      });
    });
    this.eventListeners.clear();
  }

  /**
   * Check if user has Apple Music subscription
   */
  async hasSubscription(): Promise<boolean> {
    const status = await this.getAuthorizationStatus();
    return status.status === 'authorized';
  }
}

// Export singleton instance
export const musicKit = new MusicKit();

// Export for direct use
export default musicKit;
