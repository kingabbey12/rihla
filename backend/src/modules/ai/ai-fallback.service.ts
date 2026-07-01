import { Injectable } from '@nestjs/common';
import { AiContext } from '../context/context-engine.service';
import { AiMode } from './prompts/system-prompts';

@Injectable()
export class AiFallbackService {
  respond(mode: AiMode, userMessage: string, context?: AiContext): string {
    const msg = userMessage.toLowerCase();
    const weather = context?.weather;
    const traffic = context?.traffic;
    const emirate = context?.location?.emirate ?? 'UAE';

    if (mode === 'emergency_assistant' || this.isEmergency(msg)) {
      return [
        'Your safety comes first.',
        'For emergencies in the UAE call 999 (police/ambulance) or 997 (civil defence).',
        context?.explore?.hospital
          ? `Nearest hospital in context: ${context.explore.hospital.name} (~${context.explore.hospital.distanceKm?.toFixed(1)} km).`
          : 'Open Explore to find the nearest hospital or police station.',
        'If possible, pull over safely before using your phone.',
      ].join(' ');
    }

    if (mode === 'journey_advisor' || msg.includes('route') || msg.includes('journey')) {
      const parts = [`Planning around ${emirate}.`];
      if (traffic) parts.push(`Traffic looks ${traffic.flowLevel} nearby.`);
      if (weather) parts.push(`Weather: ${weather.description}, ${weather.temperatureC}°C.`);
      if (context?.journey?.destination) {
        parts.push(`Destination: ${context.journey.destination}.`);
      }
      parts.push('Consider fuel or EV stops on longer drives and allow extra time during rush hour (7–9 AM, 5–8 PM).');
      return parts.join(' ');
    }

    if (mode === 'search_assistant' || msg.includes('find') || msg.includes('where')) {
      return `Try searching "${userMessage}" with an emirate name (e.g. Dubai, Abu Dhabi) for better UAE results. I can help refine queries for malls, metro stations, communities, and landmarks.`;
    }

    if (mode === 'travel_planner') {
      const temp = weather?.temperatureC ?? 32;
      return `For ${emirate}: ${temp > 38 ? 'Stay hydrated and plan indoor stops midday.' : 'Good conditions for sightseeing.'} ${traffic?.flowLevel === 'heavy' ? 'Allow extra travel time due to traffic.' : ''} Ask about specific attractions or dining areas.`;
    }

    // driving_assistant default
    if (msg.includes('salik') || msg.includes('toll')) {
      return 'Salik toll gates operate on major Dubai routes. Ensure your tag is active or register a day pass. Watch lane markings when approaching gates.';
    }
    if (msg.includes('speed')) {
      return 'UAE urban limits are typically 60–80 km/h; highways 100–140 km/h where signed. Speed cameras are common — maintain a safe buffer below the limit.';
    }

    const trafficNote = traffic ? ` Current traffic: ${traffic.flowLevel}.` : '';
    const weatherNote = weather ? ` ${weather.description}, ${weather.temperatureC}°C.` : '';
    return `I'm here to help with UAE driving.${weatherNote}${trafficNote} Ask about routes, traffic, parking, fuel stops, or emergencies.`;
  }

  private isEmergency(msg: string): boolean {
    return /emergency|accident|crash|ambulance|police|help|hospital|breakdown/.test(msg);
  }
}
