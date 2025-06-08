# Enhanced Kyukei-Panda: Enterprise Productivity Platform

## 🎯 Project Overview

**IMPORTANT**: This prompt is for enhancing the existing **Kyukei-Panda** project (https://github.com/crestamr/kyukei-panda) - a Laravel + Vue.js + Electron time tracking application.

**Current Foundation:**
- ✅ **Laravel 12** backend with Inertia.js
- ✅ **Vue 3 + TypeScript** frontend with Tailwind CSS
- ✅ **NativePHP/Electron** for desktop application
- ✅ **Basic time tracking** functionality
- ✅ **SQLite database** for local storage
- ✅ **Multi-language support** (EN, FR, DE, CN)

**Enhancement Goal:**
Transform the existing TimeScribe/Kyukei-Panda into a comprehensive enterprise productivity platform with advanced features including automatic activity monitoring, AI-powered analytics, team collaboration, and the unique **Kyukei-Panda (休憩パンダ)** Slack integration for Japanese work culture.

## 📋 Core Requirements

### Primary Features
1. **Automatic Time Tracking** - Monitor user activity across applications and websites
2. **AI-Powered Analytics** - Categorize activities and provide productivity insights
3. **Project & Client Management** - Organize work by projects and clients
4. **Team Collaboration** - Multi-user support with team dashboards
5. **Distraction Blocking** - Built-in website/app blocker during focus sessions
6. **Advanced Reporting** - Detailed analytics with export capabilities
7. **API Integration** - GraphQL API for third-party integrations
8. **Kyukei-Panda System** - Slack-based break tracking with panda emojis

### 🐼 Special Requirement: Kyukei-Panda (休憩パンダ) System

**Cultural Context**: In Japanese work culture, proper break management is essential for employee wellbeing and productivity.

**Implementation Requirements**:
- **Slack Integration**: Monitor designated Slack channels for panda emoji posts
- **Break Tracking**: Each 🐼 emoji = 10 minutes break time
- **Daily Limit**: Maximum 6 panda emojis per employee per day (60 minutes total)
- **Real-time Monitoring**: Automatically track when employees post panda emojis
- **Dashboard Integration**: Show break usage in employee dashboards
- **Team Visibility**: Managers can see team break patterns (anonymized)
- **Compliance**: Ensure employees take adequate breaks per Japanese labor laws
- **Notifications**: Alert employees when they approach daily limit
- **Reporting**: Generate break compliance reports for HR

## 🏗️ Enhanced System Architecture

### Current Technology Stack (Keep & Enhance)
```
Frontend (Current):
✅ Vue 3 + TypeScript + Composition API
✅ Tailwind CSS 4.1.7 for styling
✅ Inertia.js for SPA-like experience
✅ Reka UI components + Lucide icons
✅ ApexCharts for data visualization
✅ Moment.js for date/time handling

Backend (Current):
✅ Laravel 12 with PHP 8.4
✅ SQLite for local data storage
✅ Spatie packages for settings & Excel export
✅ Laravel Tinker for debugging
✅ Multi-language support (Laravel Lang)

Desktop Application (Current):
✅ NativePHP/Electron for cross-platform
✅ Native OS integration
✅ Auto-updater functionality
✅ Menu bar integration

NEW ADDITIONS NEEDED:
+ Slack API integration for Kyukei-Panda
+ Background activity monitoring service
+ AI categorization engine (local ML models)
+ Real-time WebSocket connections
+ Team collaboration features
+ Advanced analytics engine
+ Export/import capabilities
+ Plugin system for integrations
```

### Enhanced Database Schema (Laravel Migrations)
```php
// EXISTING TABLES (Keep & Enhance):
// - users (enhance with team features)
// - time_entries (enhance with categories)
// - settings (using Spatie Laravel Settings)

// NEW MIGRATIONS TO CREATE:

// Migration: create_teams_table
Schema::create('teams', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('slug')->unique();
    $table->json('settings')->nullable();
    $table->timestamps();
});

// Migration: create_team_user_table
Schema::create('team_user', function (Blueprint $table) {
    $table->id();
    $table->foreignId('team_id')->constrained()->onDelete('cascade');
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('role')->default('member'); // admin, manager, member
    $table->timestamps();
});

// Migration: create_projects_table
Schema::create('projects', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->text('description')->nullable();
    $table->string('color', 7)->default('#3B82F6');
    $table->foreignId('team_id')->constrained()->onDelete('cascade');
    $table->foreignId('client_id')->nullable()->constrained()->onDelete('set null');
    $table->boolean('is_active')->default(true);
    $table->timestamps();
});

// Migration: create_clients_table
Schema::create('clients', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->nullable();
    $table->text('notes')->nullable();
    $table->foreignId('team_id')->constrained()->onDelete('cascade');
    $table->timestamps();
});

// Migration: create_categories_table
Schema::create('categories', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('color', 7)->default('#10B981');
    $table->decimal('productivity_score', 3, 2)->default(0.50); // 0.00-1.00
    $table->boolean('is_productive')->default(true);
    $table->foreignId('team_id')->nullable()->constrained()->onDelete('cascade');
    $table->timestamps();
});

// Migration: create_activities_table
Schema::create('activities', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('application_name');
    $table->string('window_title')->nullable();
    $table->string('url')->nullable();
    $table->foreignId('category_id')->nullable()->constrained()->onDelete('set null');
    $table->timestamp('started_at');
    $table->timestamp('ended_at')->nullable();
    $table->integer('duration_seconds')->default(0);
    $table->decimal('productivity_score', 3, 2)->nullable();
    $table->timestamps();
});

// Migration: create_panda_breaks_table (KYUKEI-PANDA FEATURE)
Schema::create('panda_breaks', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->string('slack_user_id');
    $table->string('slack_channel_id');
    $table->string('slack_message_ts');
    $table->integer('panda_count')->default(1);
    $table->integer('break_duration')->default(10); // minutes
    $table->timestamp('break_timestamp');
    $table->boolean('is_valid')->default(true);
    $table->timestamps();
});

// Migration: create_daily_panda_limits_table
Schema::create('daily_panda_limits', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->date('date');
    $table->integer('pandas_used')->default(0);
    $table->integer('total_break_minutes')->default(0);
    $table->timestamp('limit_exceeded_at')->nullable();
    $table->timestamps();
    $table->unique(['user_id', 'date']);
});

// Migration: create_slack_integrations_table
Schema::create('slack_integrations', function (Blueprint $table) {
    $table->id();
    $table->foreignId('team_id')->constrained()->onDelete('cascade');
    $table->string('slack_team_id');
    $table->string('slack_channel_id');
    $table->string('channel_name');
    $table->boolean('is_panda_enabled')->default(true);
    $table->json('settings')->nullable();
    $table->timestamps();
});
```

## 🎨 User Interface Requirements

### Dashboard Components
1. **Real-time Activity Monitor** - Current application/website being used
2. **Daily/Weekly/Monthly Analytics** - Time distribution charts and graphs
3. **Project Timeline** - Visual representation of time spent on projects
4. **Focus Score** - AI-calculated productivity metrics
5. **Break Tracker** - Kyukei-Panda usage with visual panda indicators
6. **Team Overview** - Aggregated team productivity (for managers)
7. **Goal Setting** - Daily/weekly productivity targets
8. **Distraction Alerts** - Real-time notifications for off-task activities

### Kyukei-Panda Interface
```
🐼 Break Dashboard:
┌─────────────────────────────────────┐
│ Today's Panda Usage: 🐼🐼🐼⚪⚪⚪    │
│ Break Time Used: 30/60 minutes     │
│ Last Break: 2:30 PM (10 min)       │
│ Next Recommended: 4:00 PM           │
│                                     │
│ Team Break Status:                  │
│ • Tanaka-san: 🐼🐼🐼🐼⚪⚪ (40 min) │
│ • Sato-san: 🐼🐼⚪⚪⚪⚪ (20 min)   │
│ • Yamada-san: 🐼🐼🐼🐼🐼🐼 (60 min) │
└─────────────────────────────────────┘
```

## 🔧 Implementation Details

### Phase 1: Foundation Enhancement (Weeks 1-4)
```
Week 1: Database & Models Enhancement
- Create new Laravel migrations for teams, projects, clients, categories
- Build Eloquent models with relationships
- Enhance existing User model with team associations
- Set up model factories and seeders for testing

Week 2: Team & Project Management
- Create team management controllers and views
- Build project and client management interfaces
- Implement role-based permissions (admin, manager, member)
- Add team invitation and user management

Week 3: Activity Monitoring Foundation
- Enhance existing time tracking with automatic activity detection
- Create activity monitoring service using NativePHP
- Build category management system
- Implement basic productivity scoring

Week 4: UI/UX Enhancement
- Enhance existing Vue components with new features
- Create team dashboard layouts
- Build project and client management interfaces
- Implement responsive design improvements
```

### Phase 2: Kyukei-Panda & Advanced Features (Weeks 5-8)
```
Week 5: Kyukei-Panda Slack Integration
- Set up Laravel Slack API integration using Socialite or custom package
- Create Slack bot commands and event listeners
- Implement panda emoji detection and break tracking
- Build panda break dashboard components

Week 6: Advanced Activity Monitoring
- Enhance NativePHP desktop app with detailed activity tracking
- Implement AI-powered activity categorization (local ML models)
- Create distraction detection and blocking features
- Add focus session management

Week 7: Analytics & Reporting
- Build comprehensive analytics dashboard with ApexCharts
- Implement productivity scoring algorithms
- Create team performance analytics
- Add export functionality (enhance existing Excel export)

Week 8: Real-time Features
- Implement WebSocket connections for real-time updates
- Add live team activity monitoring
- Create real-time panda break notifications
- Build live productivity dashboards
```

### Phase 3: Enterprise & Integration Features (Weeks 9-12)
```
Week 9: API & Integrations
- Build RESTful API endpoints for mobile/third-party access
- Create webhook system for external integrations
- Implement calendar integrations (Google, Outlook)
- Add project management tool integrations (Jira, Asana)

Week 10: Advanced Team Features
- Build manager dashboards with team oversight
- Implement advanced permission systems
- Create team productivity benchmarking
- Add team goal setting and tracking

Week 11: Enterprise Security & Compliance
- Implement advanced security features
- Add audit logging and compliance reporting
- Create data export/import tools for enterprise
- Build admin panel for system management

Week 12: Polish & Deployment
- Performance optimization and testing
- Create deployment scripts and documentation
- Implement auto-update mechanisms
- Final UI/UX polish and accessibility improvements
```

## 🐼 Kyukei-Panda Implementation Guide

### Laravel Slack Integration Setup
```php
// app/Services/SlackService.php
<?php

namespace App\Services;

use App\Models\User;
use App\Models\PandaBreak;
use App\Models\DailyPandaLimit;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class SlackService
{
    private string $botToken;
    private string $signingSecret;

    public function __construct()
    {
        $this->botToken = config('services.slack.bot_token');
        $this->signingSecret = config('services.slack.signing_secret');
    }

    public function handlePandaMessage(array $event): void
    {
        if (!isset($event['text']) || !str_contains($event['text'], '🐼')) {
            return;
        }

        $pandaCount = substr_count($event['text'], '🐼');
        $user = User::where('slack_user_id', $event['user'])->first();

        if (!$user) {
            $this->sendSlackMessage($event['channel'],
                "Please link your Slack account to Kyukei-Panda first! 🔗");
            return;
        }

        $result = $this->processPandaBreak([
            'user_id' => $user->id,
            'slack_user_id' => $event['user'],
            'slack_channel_id' => $event['channel'],
            'slack_message_ts' => $event['ts'],
            'panda_count' => $pandaCount,
            'break_timestamp' => Carbon::createFromTimestamp($event['ts'])
        ]);

        if ($result['success']) {
            $this->sendSlackMessage($event['channel'], [
                'text' => "🐼 Break time recorded!",
                'blocks' => [
                    [
                        'type' => 'section',
                        'text' => [
                            'type' => 'mrkdwn',
                            'text' => "*Break Recorded!* 🐼\n" .
                                     "Duration: {$result['duration']} minutes\n" .
                                     "Daily usage: {$result['daily_usage']}/6 pandas\n" .
                                     "Remaining: {$result['remaining_minutes']} minutes"
                        ]
                    ],
                    [
                        'type' => 'context',
                        'elements' => [
                            [
                                'type' => 'mrkdwn',
                                'text' => '💡 *Tip:* Regular breaks improve productivity!'
                            ]
                        ]
                    ]
                ]
            ]);
        } else {
            $this->sendSlackMessage($event['channel'], "🚫 {$result['message']}");
        }
    }

    public function processPandaBreak(array $data): array
    {
        $today = Carbon::today();
        $dailyLimit = DailyPandaLimit::firstOrCreate([
            'user_id' => $data['user_id'],
            'date' => $today
        ]);

        $newTotal = $dailyLimit->pandas_used + $data['panda_count'];

        if ($newTotal > 6) {
            return [
                'success' => false,
                'message' => 'Daily panda limit exceeded! You can only use 6 pandas per day.'
            ];
        }

        // Record the panda break
        PandaBreak::create([
            'user_id' => $data['user_id'],
            'slack_user_id' => $data['slack_user_id'],
            'slack_channel_id' => $data['slack_channel_id'],
            'slack_message_ts' => $data['slack_message_ts'],
            'panda_count' => $data['panda_count'],
            'break_duration' => $data['panda_count'] * 10,
            'break_timestamp' => $data['break_timestamp']
        ]);

        // Update daily limit
        $dailyLimit->update([
            'pandas_used' => $newTotal,
            'total_break_minutes' => $dailyLimit->total_break_minutes + ($data['panda_count'] * 10)
        ]);

        return [
            'success' => true,
            'duration' => $data['panda_count'] * 10,
            'daily_usage' => $newTotal,
            'remaining_minutes' => (6 - $newTotal) * 10
        ];
    }

    private function sendSlackMessage(string $channel, $message): void
    {
        $payload = is_array($message) ? $message : ['text' => $message];
        $payload['channel'] = $channel;

        Http::withHeaders([
            'Authorization' => "Bearer {$this->botToken}",
            'Content-Type' => 'application/json'
        ])->post('https://slack.com/api/chat.postMessage', $payload);
    }
}

// app/Http/Controllers/SlackController.php
<?php

namespace App\Http\Controllers;

use App\Services\SlackService;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class SlackController extends Controller
{
    public function __construct(private SlackService $slackService)
    {
    }

    public function events(Request $request): Response
    {
        // Verify Slack signature
        if (!$this->verifySlackSignature($request)) {
            return response('Unauthorized', 401);
        }

        $payload = $request->json()->all();

        // Handle URL verification challenge
        if ($payload['type'] === 'url_verification') {
            return response($payload['challenge']);
        }

        // Handle message events
        if ($payload['type'] === 'event_callback' && $payload['event']['type'] === 'message') {
            $this->slackService->handlePandaMessage($payload['event']);
        }

        return response('OK');
    }

    public function slashCommand(Request $request): Response
    {
        if (!$this->verifySlackSignature($request)) {
            return response('Unauthorized', 401);
        }

        $command = $request->input('command');
        $userId = $request->input('user_id');

        if ($command === '/panda-status') {
            return $this->handlePandaStatusCommand($userId);
        }

        return response('Unknown command');
    }

    private function handlePandaStatusCommand(string $slackUserId): Response
    {
        $user = User::where('slack_user_id', $slackUserId)->first();

        if (!$user) {
            return response()->json([
                'text' => 'Please link your Slack account to Kyukei-Panda first!'
            ]);
        }

        $dailyUsage = DailyPandaLimit::where('user_id', $user->id)
            ->where('date', Carbon::today())
            ->first();

        $pandasUsed = $dailyUsage?->pandas_used ?? 0;
        $pandaEmojis = str_repeat('🐼', $pandasUsed) . str_repeat('⚪', 6 - $pandasUsed);

        return response()->json([
            'text' => 'Your panda break status',
            'blocks' => [
                [
                    'type' => 'header',
                    'text' => [
                        'type' => 'plain_text',
                        'text' => '🐼 Your Panda Break Status'
                    ]
                ],
                [
                    'type' => 'section',
                    'fields' => [
                        [
                            'type' => 'mrkdwn',
                            'text' => "*Today's Usage:*\n{$pandaEmojis}"
                        ],
                        [
                            'type' => 'mrkdwn',
                            'text' => "*Break Time:*\n{$dailyUsage?->total_break_minutes ?? 0}/60 minutes"
                        ]
                    ]
                ]
            ]
        ]);
    }

    private function verifySlackSignature(Request $request): bool
    {
        $timestamp = $request->header('X-Slack-Request-Timestamp');
        $signature = $request->header('X-Slack-Signature');

        if (abs(time() - $timestamp) > 60 * 5) {
            return false; // Request too old
        }

        $body = $request->getContent();
        $expectedSignature = 'v0=' . hash_hmac('sha256', "v0:{$timestamp}:{$body}", config('services.slack.signing_secret'));

        return hash_equals($expectedSignature, $signature);
    }
}
```

### Break Analytics Dashboard
```javascript
// Kyukei-Panda Analytics Component
const PandaBreakDashboard = () => {
  const [breakData, setBreakData] = useState(null);
  const [teamBreaks, setTeamBreaks] = useState([]);

  return (
    <div className="panda-dashboard">
      <h2>🐼 Kyukei-Panda Break Tracker</h2>

      <div className="daily-usage">
        <div className="panda-counter">
          {Array.from({length: 6}, (_, i) => (
            <span key={i} className={i < breakData.used ? 'used' : 'available'}>
              {i < breakData.used ? '🐼' : '⚪'}
            </span>
          ))}
        </div>
        <p>Break Time: {breakData.totalMinutes}/60 minutes</p>
      </div>

      <div className="team-overview">
        <h3>Team Break Status</h3>
        {teamBreaks.map(member => (
          <div key={member.id} className="team-member">
            <span>{member.name}:</span>
            <span className="panda-usage">
              {'🐼'.repeat(member.pandasUsed)}
              {'⚪'.repeat(6 - member.pandasUsed)}
            </span>
            <span>({member.totalMinutes} min)</span>
          </div>
        ))}
      </div>
    </div>
  );
};
```

## 📊 Key Metrics & Analytics

### Productivity Metrics
- **Focus Score**: AI-calculated based on time spent on productive vs. distracting activities
- **Deep Work Sessions**: Uninterrupted work periods longer than 25 minutes
- **Context Switching**: Frequency of application/task changes
- **Peak Productivity Hours**: Time periods with highest focus scores

### Kyukei-Panda Metrics
- **Break Compliance**: Percentage of employees taking adequate breaks
- **Break Timing**: Analysis of when breaks are most commonly taken
- **Productivity Correlation**: Relationship between break patterns and productivity
- **Team Break Synchronization**: How team break patterns affect collaboration

### Reporting Features
```
Daily Reports:
- Individual productivity summary
- Break compliance status
- Goal achievement tracking

Weekly Reports:
- Productivity trends
- Project time allocation
- Team collaboration metrics

Monthly Reports:
- Comprehensive analytics
- Goal vs. actual performance
- Break pattern analysis
- Recommendations for improvement
```

## 🔐 Security & Compliance

### Data Protection
- **End-to-end encryption** for sensitive productivity data
- **GDPR compliance** for European users
- **SOC 2 Type II** certification for enterprise customers
- **Role-based access control** for team features

### Japanese Labor Law Compliance
- **Break time tracking** to ensure legal compliance
- **Overtime monitoring** with automatic alerts
- **Work-life balance** metrics and recommendations
- **Privacy protection** for employee monitoring data

## 🚀 Deployment & Scaling

### Infrastructure Requirements
```
Production Environment:
- Load balancer (AWS ALB/GCP Load Balancer)
- Auto-scaling groups for API servers
- Database clustering (PostgreSQL with read replicas)
- Redis cluster for caching and real-time features
- CDN for static assets
- Monitoring and alerting (Prometheus, Grafana, PagerDuty)

Development Environment:
- Docker Compose for local development
- Automated testing pipeline
- Staging environment for QA
- Feature flag system for gradual rollouts
```

### Performance Targets
- **API Response Time**: < 200ms for 95% of requests
- **Desktop App**: < 5% CPU usage during background monitoring
- **Real-time Updates**: < 1 second latency for dashboard updates
- **Uptime**: 99.9% availability SLA

## 📝 Success Criteria

### Technical Milestones
- [ ] Automatic activity tracking with 95% accuracy
- [ ] Real-time Slack integration for panda emoji detection
- [ ] Sub-200ms API response times
- [ ] Cross-platform desktop application
- [ ] Comprehensive analytics dashboard

### Business Objectives
- [ ] Improve employee break compliance by 40%
- [ ] Increase team productivity visibility
- [ ] Reduce manual time tracking overhead by 80%
- [ ] Achieve 90% user adoption within 3 months
- [ ] Maintain 95% user satisfaction score

## 🎌 Cultural Considerations

### Japanese Work Culture Integration
- **Respect for hierarchy**: Manager dashboards with appropriate visibility levels
- **Group harmony**: Team-focused features rather than individual competition
- **Work-life balance**: Emphasis on proper break taking and overtime awareness
- **Continuous improvement (Kaizen)**: Regular productivity insights and recommendations

### Kyukei-Panda Cultural Benefits
- **Gamification**: Makes break-taking fun and socially acceptable
- **Peer awareness**: Encourages team members to take breaks together
- **Management visibility**: Helps managers ensure team wellbeing
- **Compliance**: Supports Japanese labor law requirements for break times

## 🛠️ Technical Implementation Examples

### Kyukei-Panda Database Schema
```sql
-- Panda break tracking tables
CREATE TABLE panda_breaks (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    slack_user_id VARCHAR(50),
    slack_channel_id VARCHAR(50),
    panda_count INTEGER DEFAULT 1,
    break_duration INTEGER DEFAULT 10, -- minutes
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_valid BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE daily_panda_limits (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    date DATE DEFAULT CURRENT_DATE,
    pandas_used INTEGER DEFAULT 0,
    total_break_minutes INTEGER DEFAULT 0,
    limit_exceeded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, date)
);

CREATE TABLE slack_channels (
    id SERIAL PRIMARY KEY,
    team_id INTEGER REFERENCES teams(id),
    slack_channel_id VARCHAR(50) UNIQUE,
    channel_name VARCHAR(100),
    is_panda_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Real-time Activity Monitoring
```javascript
// Desktop app activity monitor
class ActivityMonitor {
  constructor() {
    this.currentActivity = null;
    this.activityBuffer = [];
    this.isMonitoring = false;
  }

  async startMonitoring() {
    this.isMonitoring = true;

    // Monitor active window every 5 seconds
    setInterval(async () => {
      if (!this.isMonitoring) return;

      const activity = await this.getCurrentActivity();
      if (this.hasActivityChanged(activity)) {
        await this.recordActivity(activity);
      }
    }, 5000);
  }

  async getCurrentActivity() {
    const activeWindow = await getActiveWindow();
    const runningApps = await getRunningApplications();

    return {
      windowTitle: activeWindow.title,
      applicationName: activeWindow.owner.name,
      url: activeWindow.url || null,
      timestamp: new Date(),
      isProductiveApp: await this.categorizeActivity(activeWindow)
    };
  }

  async categorizeActivity(window) {
    // AI-powered categorization
    const category = await this.aiCategorizer.categorize({
      appName: window.owner.name,
      windowTitle: window.title,
      url: window.url
    });

    return {
      category: category.name,
      productivityScore: category.score,
      isDistraction: category.score < 0.3
    };
  }
}
```

### Slack Bot Implementation
```javascript
// Kyukei-Panda Slack Bot
const { App } = require('@slack/bolt');

const pandaBot = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  appToken: process.env.SLACK_APP_TOKEN,
  socketMode: true
});

// Listen for panda emoji messages
pandaBot.message(/🐼/, async ({ message, say, client }) => {
  try {
    const pandaCount = (message.text.match(/🐼/g) || []).length;
    const user = await getUserBySlackId(message.user);

    if (!user) {
      await say("Please link your Slack account to your productivity dashboard first!");
      return;
    }

    const result = await processPandaBreak({
      userId: user.id,
      slackUserId: message.user,
      channelId: message.channel,
      pandaCount: pandaCount,
      timestamp: message.ts
    });

    if (result.success) {
      await say({
        text: `🐼 Break time recorded! ${pandaCount * 10} minutes`,
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: `*Break Recorded!* 🐼\n` +
                    `Duration: ${pandaCount * 10} minutes\n` +
                    `Daily usage: ${result.dailyUsage}/6 pandas\n` +
                    `Remaining: ${(6 - result.dailyUsage) * 10} minutes`
            }
          },
          {
            type: "context",
            elements: [
              {
                type: "mrkdwn",
                text: `💡 *Tip:* Take regular breaks to maintain productivity!`
              }
            ]
          }
        ]
      });
    } else {
      await say(`🚫 ${result.message}`);
    }
  } catch (error) {
    console.error('Panda break processing error:', error);
    await say("Sorry, there was an error processing your break. Please try again!");
  }
});

// Daily panda usage summary
pandaBot.command('/panda-status', async ({ command, ack, say }) => {
  await ack();

  const user = await getUserBySlackId(command.user_id);
  const dailyUsage = await getDailyPandaUsage(user.id);
  const teamUsage = await getTeamPandaUsage(user.team_id);

  await say({
    text: "Your panda break status",
    blocks: [
      {
        type: "header",
        text: {
          type: "plain_text",
          text: "🐼 Your Panda Break Status"
        }
      },
      {
        type: "section",
        fields: [
          {
            type: "mrkdwn",
            text: `*Today's Usage:*\n${'🐼'.repeat(dailyUsage.pandas_used)}${'⚪'.repeat(6 - dailyUsage.pandas_used)}`
          },
          {
            type: "mrkdwn",
            text: `*Break Time:*\n${dailyUsage.total_minutes}/60 minutes`
          }
        ]
      },
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: `*Team Average:* ${teamUsage.average_pandas}/6 pandas`
        }
      }
    ]
  });
});
```

### AI-Powered Productivity Analytics
```python
# Productivity scoring algorithm
class ProductivityAnalyzer:
    def __init__(self):
        self.category_weights = {
            'development': 1.0,
            'communication': 0.8,
            'research': 0.9,
            'documentation': 0.85,
            'meetings': 0.7,
            'social_media': 0.1,
            'entertainment': 0.0,
            'breaks': 0.5  # Breaks are important for productivity
        }

    def calculate_focus_score(self, activities, break_data):
        """Calculate daily focus score (0-100)"""
        total_time = sum(a.duration for a in activities)
        if total_time == 0:
            return 0

        # Base productivity score
        weighted_time = sum(
            a.duration * self.category_weights.get(a.category, 0.5)
            for a in activities
        )
        base_score = (weighted_time / total_time) * 100

        # Break bonus: proper breaks improve focus
        break_bonus = self.calculate_break_bonus(break_data)

        # Context switching penalty
        switching_penalty = self.calculate_switching_penalty(activities)

        final_score = min(100, max(0,
            base_score + break_bonus - switching_penalty
        ))

        return round(final_score, 1)

    def calculate_break_bonus(self, break_data):
        """Bonus for taking appropriate breaks"""
        if not break_data:
            return -10  # Penalty for no breaks

        pandas_used = break_data.get('pandas_used', 0)

        if pandas_used == 0:
            return -10  # No breaks taken
        elif 2 <= pandas_used <= 4:
            return 5   # Optimal break frequency
        elif pandas_used <= 6:
            return 2   # Good break frequency
        else:
            return -5  # Too many breaks

    def calculate_switching_penalty(self, activities):
        """Penalty for excessive context switching"""
        if len(activities) <= 1:
            return 0

        switches = 0
        for i in range(1, len(activities)):
            if activities[i].category != activities[i-1].category:
                switches += 1

        # Penalty increases with excessive switching
        if switches > 20:
            return 15
        elif switches > 10:
            return 8
        elif switches > 5:
            return 3
        else:
            return 0
```

### Vue.js Components (Compatible with Existing Project)
```vue
<!-- resources/js/Components/KyukeiPandaDashboard.vue -->
<template>
  <div class="kyukei-panda-dashboard">
    <div class="dashboard-header">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
        🐼 Kyukei-Panda Break Tracker
      </h2>
      <div class="date-selector text-sm text-gray-500">
        {{ formatDate(new Date()) }}
      </div>
    </div>

    <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      <!-- Panda Usage Card -->
      <div class="panda-usage-card bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold mb-4">Today's Panda Usage</h3>

        <div class="panda-counter flex justify-center gap-2 mb-4">
          <span
            v-for="(panda, index) in 6"
            :key="index"
            :class="['text-3xl cursor-pointer transition-transform hover:scale-110',
                     index < pandasUsed ? 'opacity-100' : 'opacity-30']"
            :title="`Panda ${index + 1}: ${index < pandasUsed ? 'Used' : 'Available'}`"
          >
            {{ index < pandasUsed ? '🐼' : '⚪' }}
          </span>
        </div>

        <div class="usage-stats space-y-2 text-sm text-gray-600 dark:text-gray-400">
          <div class="flex justify-between">
            <span>Break Time:</span>
            <span>{{ totalBreakMinutes }}/60 minutes</span>
          </div>
          <div class="flex justify-between">
            <span>Pandas Used:</span>
            <span>{{ pandasUsed }}/6</span>
          </div>
        </div>

        <div class="recommendation mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
          <p class="text-sm text-blue-700 dark:text-blue-300">
            {{ getBreakRecommendation() }}
          </p>
        </div>
      </div>

      <!-- Team Overview Card -->
      <div class="team-overview-card bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold mb-4">Team Break Status</h3>

        <div class="team-grid space-y-3">
          <div
            v-for="member in teamBreaks"
            :key="member.id"
            class="team-member-card flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg"
          >
            <div class="member-info">
              <div class="member-name font-medium">{{ member.name }}</div>
              <div class="member-time text-sm text-gray-500">{{ member.total_minutes }} min</div>
            </div>
            <div class="member-pandas text-lg">
              {{ '🐼'.repeat(member.pandas_used) }}{{ '⚪'.repeat(6 - member.pandas_used) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Break History Card -->
      <div class="break-history-card bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold mb-4">Recent Breaks</h3>

        <div class="break-timeline space-y-3">
          <div
            v-for="breakItem in recentBreaks"
            :key="breakItem.id"
            class="break-item flex items-center justify-between p-3 border-l-4 border-blue-500 bg-gray-50 dark:bg-gray-700"
          >
            <div class="break-info">
              <div class="break-time font-medium">
                {{ formatTime(breakItem.break_timestamp) }}
              </div>
              <div class="break-channel text-sm text-gray-500">
                #{{ breakItem.channel_name }}
              </div>
            </div>
            <div class="break-duration">
              <span class="text-lg">{{ '🐼'.repeat(breakItem.panda_count) }}</span>
              <span class="text-sm text-gray-500 ml-2">({{ breakItem.break_duration }} min)</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="quick-actions mt-6 flex gap-4">
      <button
        @click="refreshData"
        class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
      >
        🔄 Refresh
      </button>

      <button
        @click="openSlackChannel"
        class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
      >
        💬 Open Slack
      </button>

      <button
        @click="viewAnalytics"
        class="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
      >
        📊 View Analytics
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { router } from '@inertiajs/vue3'
import moment from 'moment'

interface PandaBreak {
  id: number
  panda_count: number
  break_duration: number
  break_timestamp: string
  channel_name: string
}

interface TeamMember {
  id: number
  name: string
  pandas_used: number
  total_minutes: number
}

interface DailyUsage {
  pandas_used: number
  total_break_minutes: number
  recent_breaks: PandaBreak[]
}

// Props
interface Props {
  userId: number
  teamId?: number
  dailyUsage?: DailyUsage
  teamBreaks?: TeamMember[]
}

const props = withDefaults(defineProps<Props>(), {
  dailyUsage: () => ({ pandas_used: 0, total_break_minutes: 0, recent_breaks: [] }),
  teamBreaks: () => []
})

// Reactive data
const pandasUsed = computed(() => props.dailyUsage?.pandas_used || 0)
const totalBreakMinutes = computed(() => props.dailyUsage?.total_break_minutes || 0)
const recentBreaks = computed(() => props.dailyUsage?.recent_breaks || [])

// Methods
const getBreakRecommendation = (): string => {
  const used = pandasUsed.value
  const lastBreak = recentBreaks.value[0]?.break_timestamp
  const timeSinceLastBreak = lastBreak ?
    moment().diff(moment(lastBreak), 'minutes') : 0

  if (used === 0) {
    return "🌟 Time for your first break! Post a 🐼 in Slack"
  } else if (used >= 6) {
    return "✅ You've used all your pandas today. Great job taking breaks!"
  } else if (timeSinceLastBreak > 120) {
    return "⏰ It's been 2+ hours since your last break. Consider posting 🐼"
  } else {
    return `💪 ${6 - used} pandas remaining. Next break recommended in ${Math.max(0, 90 - timeSinceLastBreak)} minutes`
  }
}

const formatDate = (date: Date): string => {
  return moment(date).format('YYYY年MM月DD日 (ddd)')
}

const formatTime = (timestamp: string): string => {
  return moment(timestamp).format('HH:mm')
}

const refreshData = (): void => {
  router.reload({ only: ['dailyUsage', 'teamBreaks'] })
}

const openSlackChannel = (): void => {
  // Open Slack in external browser or app
  window.open('slack://channel?team=YOUR_TEAM_ID&id=YOUR_CHANNEL_ID', '_blank')
}

const viewAnalytics = (): void => {
  router.visit('/analytics/panda-breaks')
}

// Lifecycle
onMounted(() => {
  // Set up real-time updates if needed
  // Could use Laravel Echo for WebSocket connections
})
</script>

<style scoped>
.panda-counter span {
  transition: all 0.3s ease;
}

.panda-counter span:hover {
  transform: scale(1.1);
}

.break-timeline {
  max-height: 300px;
  overflow-y: auto;
}

.team-grid {
  max-height: 300px;
  overflow-y: auto;
}
</style>
```

```php
// app/Http/Controllers/PandaDashboardController.php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\PandaBreak;
use App\Models\DailyPandaLimit;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Carbon\Carbon;

class PandaDashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today();

        // Get daily usage
        $dailyUsage = DailyPandaLimit::where('user_id', $user->id)
            ->where('date', $today)
            ->first();

        // Get recent breaks
        $recentBreaks = PandaBreak::where('user_id', $user->id)
            ->where('break_timestamp', '>=', $today)
            ->orderBy('break_timestamp', 'desc')
            ->limit(10)
            ->get();

        // Get team breaks (if user is part of a team)
        $teamBreaks = [];
        if ($user->teams()->exists()) {
            $teamBreaks = $user->teams()->first()
                ->users()
                ->with(['dailyPandaLimits' => function ($query) use ($today) {
                    $query->where('date', $today);
                }])
                ->get()
                ->map(function ($member) {
                    $dailyLimit = $member->dailyPandaLimits->first();
                    return [
                        'id' => $member->id,
                        'name' => $member->name,
                        'pandas_used' => $dailyLimit?->pandas_used ?? 0,
                        'total_minutes' => $dailyLimit?->total_break_minutes ?? 0,
                    ];
                });
        }

        return Inertia::render('PandaDashboard', [
            'userId' => $user->id,
            'teamId' => $user->teams()->first()?->id,
            'dailyUsage' => [
                'pandas_used' => $dailyUsage?->pandas_used ?? 0,
                'total_break_minutes' => $dailyUsage?->total_break_minutes ?? 0,
                'recent_breaks' => $recentBreaks->map(function ($break) {
                    return [
                        'id' => $break->id,
                        'panda_count' => $break->panda_count,
                        'break_duration' => $break->break_duration,
                        'break_timestamp' => $break->break_timestamp->toISOString(),
                        'channel_name' => 'general', // You might want to store this
                    ];
                })
            ],
            'teamBreaks' => $teamBreaks
        ]);
    }

    public function analytics(Request $request)
    {
        $user = $request->user();
        $period = $request->input('period', 'week'); // week, month, year

        $startDate = match($period) {
            'week' => Carbon::now()->startOfWeek(),
            'month' => Carbon::now()->startOfMonth(),
            'year' => Carbon::now()->startOfYear(),
            default => Carbon::now()->startOfWeek()
        };

        // Get break analytics
        $breakAnalytics = PandaBreak::where('user_id', $user->id)
            ->where('break_timestamp', '>=', $startDate)
            ->selectRaw('DATE(break_timestamp) as date, SUM(panda_count) as total_pandas, SUM(break_duration) as total_minutes')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return Inertia::render('PandaAnalytics', [
            'analytics' => $breakAnalytics,
            'period' => $period
        ]);
    }
}
```

---

**This comprehensive prompt provides everything needed to build a world-class productivity platform with the unique Kyukei-Panda system. The Japanese cultural integration transforms break management from a compliance requirement into an engaging, team-building activity that promotes employee wellbeing while maintaining detailed productivity insights.**
