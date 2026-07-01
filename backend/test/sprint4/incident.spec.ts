import { IncidentReportingService } from '../../src/modules/emergency/services/incident-reporting.service';

describe('IncidentReportingService', () => {
  const prisma = {
    incidentReport: {
      create: jest.fn(),
      findMany: jest.fn(),
    },
  };
  const dispatcher = { dispatch: jest.fn().mockResolvedValue(undefined) };
  const notifications = { notifyIncidentUpdate: jest.fn().mockResolvedValue(undefined) };

  let service: IncidentReportingService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new IncidentReportingService(
      prisma as never,
      dispatcher as never,
      notifications as never,
    );
  });

  it('stores incident with images and voice metadata', async () => {
    prisma.incidentReport.create.mockResolvedValue({
      id: 'i1',
      type: 'accident',
      status: 'submitted',
      latitude: 25.2,
      longitude: 55.3,
      description: 'Minor collision',
      imageUrls: ['https://cdn/img1.jpg'],
      voiceNoteUrl: 'https://cdn/voice.m4a',
      voiceNoteMeta: { durationSec: 12 },
      reporterName: 'User',
      reporterPhone: '+97150',
      createdAt: new Date(),
    });

    const result = await service.report('user-1', {
      type: 'accident',
      latitude: 25.2,
      longitude: 55.3,
      description: 'Minor collision',
      imageUrls: ['https://cdn/img1.jpg'],
      voiceNoteUrl: 'https://cdn/voice.m4a',
      voiceNoteMeta: { durationSec: 12 },
    });

    expect(result.success).toBe(true);
    expect(result.incident.type).toBe('accident');
    expect(dispatcher.dispatch).toHaveBeenCalledWith(
      'user-1',
      'incident',
      'i1',
      'submitted',
      expect.objectContaining({ hasImages: true, hasVoiceNote: true }),
    );
  });
});
