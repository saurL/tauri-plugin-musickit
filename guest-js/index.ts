import { invoke } from '@tauri-apps/api/core';
import { listen, type UnlistenFn } from '@tauri-apps/api/event';
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
  private eventListeners: Map<string, UnlistenFn[]> = new Map();

  /**
   * Initialize MusicKit
   */
  async initialize(): Promise<void> {
    await invoke('plugin:apple-music-kit|initialize');
  }

  /**
   * Request authorization to access Apple Music
   */
  async authorize(): Promise<AuthorizationResponse> {
    return await invoke('plugin:apple-music-kit|authorize');
  }

  /**
   * Unauthorize access to Apple Music
   */
  async unauthorize(): Promise<UnauthorizeResponse> {
    return await invoke('plugin:apple-music-kit|unauthorize');
  }

  /**
   * Get current authorization status
   */
  async getAuthorizationStatus(): Promise<AuthorizationStatusResponse> {
    return await invoke('plugin:apple-music-kit|get_authorization_status');
  }

  /**
   * Get user token
   */
  async getUserToken(): Promise<string | null> {
    return await invoke('plugin:apple-music-kit|get_user_token');
  }

  /**
   * Get developer token
   */
  async getDeveloperToken(): Promise<string | null> {
    return await invoke('plugin:apple-music-kit|get_developer_token');
  }

  /**
   * Get storefront information
   */
  async getStorefrontId(): Promise<string | null> {
    return await invoke('plugin:apple-music-kit|get_storefront_id');
  }

  /**
   * Get current queue
   */
  async getQueue(): Promise<QueueResponse> {
    return await invoke('plugin:apple-music-kit|get_queue');
  }

  /**
   * Start playback
   */
  async play(): Promise<void> {
    await invoke('plugin:apple-music-kit|play');
  }

  /**
   * Pause playback
   */
  async pause(): Promise<void> {
    await invoke('plugin:apple-music-kit|pause');
  }

  /**
   * Stop playback
   */
  async stop(): Promise<void> {
    await invoke('plugin:apple-music-kit|stop');
  }

  /**
   * Seek to specific time
   */
  async seek(timeInSeconds: number): Promise<void> {
    await invoke('plugin:apple-music-kit|seek', { time: timeInSeconds });
  }

  /**
   * Skip to next track
   */
  async next(): Promise<void> {
    await invoke('plugin:apple-music-kit|next');
  }

  /**
   * Skip to previous track
   */
  async previous(): Promise<void> {
    await invoke('plugin:apple-music-kit|previous');
  }

  /**
   * Skip to specific track
   */
  async skipToItem(trackId: string, startPlaying: boolean): Promise<void> {
    await invoke('plugin:apple-music-kit|skip_to_item', { trackId, startPlaying });
  }

  /**
   * Set volume
   */
  async setVolume(volume: number): Promise<void> {
    await invoke('plugin:apple-music-kit|set_volume', { volume });
  }

  /**
   * Set the playback queue
   */
  async setQueue(tracks: MusicKitTrack[], startPlaying: boolean = false): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|set_queue', { tracks, startPlaying });
  }

  /**
   * Update queue
   */
  async updateQueue(tracks: MusicKitTrack[]): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|update_queue', { tracks });
  }

  /**
   * Insert track at position
   */
  async insertTrackAtPosition(track: MusicKitTrack, position: number): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|insert_track_at_position', { track, position });
  }

  /**
   * Insert tracks at position
   */
  async insertTracksAtPosition(tracks: MusicKitTrack[], position: number): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|insert_tracks_at_position', { tracks, position });
  }

  /**
   * Remove track from queue
   */
  async removeTrackFromQueue(trackId: string): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|remove_track_from_queue', { trackId });
  }

  /**
   * Insert track next
   */
  async insertTrackNext(track: MusicKitTrack): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|insert_track_next', { track });
  }

  /**
   * Insert track last
   */
  async insertTrackLast(track: MusicKitTrack): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|insert_track_last', { track });
  }

  /**
   * Append tracks to queue
   */
  async appendTracksToQueue(tracks: MusicKitTrack[]): Promise<QueueOperationResponse> {
    return await invoke('plugin:apple-music-kit|append_tracks_to_queue', { tracks });
  }

  /**
   * Listen to MusicKit events
   */
  async addEventListener<K extends keyof MusicKitEventMap>(
    event: K,
    callback: (payload: MusicKitEventMap[K]) => void
  ): Promise<UnlistenFn> {
    const unlisten = await listen(event, (e) => {
      callback(e.payload as MusicKitEventMap[K]);
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
      listeners.forEach((unlisten) => unlisten());
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
