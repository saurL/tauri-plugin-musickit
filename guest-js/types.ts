export interface MusicKitTrack {
  id: string;
  title: string;
  artist: string;
  album: string;
  duration: number;
  artworkUrl?: string;
  isExplicit: boolean;
  isPlayable: boolean;
}

export interface AuthorizationResponse {
  status: 'authorized' | 'notAuthorized' | 'error';
  error?: string;
}

export interface UnauthorizeResponse {
  status: 'unauthorized' | 'error';
  error?: string;
}

export interface AuthorizationStatusResponse {
  status: 'authorized' | 'notAuthorized' | 'notInitialized';
}

export interface QueueResponse {
  items: MusicKitTrack[];
  position: number;
}

export interface QueueOperationResponse {
  success: boolean;
  error?: string;
}

export interface StateUpdateEvent {
  playing: boolean;
  currentTrack?: MusicKitTrack;
  currentTime: number;
  duration: number;
  queuePosition: number;
  shuffleMode: string;
  repeatMode: string;
  volume: number;
}

export interface QueueUpdateEvent {
  items: MusicKitTrack[];
  position: number;
}

export interface TrackChangeEvent {
  track: MusicKitTrack;
}

export interface ErrorEvent {
  error: string;
  code?: string;
}

export interface MusicKitEventMap {
  'PLAYER_ADAPTER_EVENTS.INITIALIZED': void;
  'PLAYER_ADAPTER_EVENTS.AUTHORIZATION_STATUS_CHANGE': AuthorizationResponse;
  'PLAYER_ADAPTER_EVENTS.STATE_UPDATE': StateUpdateEvent;
  'PLAYER_ADAPTER_EVENTS.QUEUE_UPDATE': QueueUpdateEvent;
  'PLAYER_ADAPTER_EVENTS.TRACK_CHANGE': TrackChangeEvent;
  'PLAYER_ADAPTER_EVENTS.ERROR': ErrorEvent;
} 