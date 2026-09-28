import http from 'http';
import { requireAuth } from '../src/middleware/requireAuth.js';

const BASE_URL = 'http://localhost:5000/api';

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', (err) => reject(err));

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('🚀 Starting Kelana API Verification Tests...\n');

  try {
    // 1. Health check
    console.log('1️⃣ Testing GET /api/health ...');
    const health = await request('GET', '/health');
    console.log('   Status:', health.status);
    console.log('   App:', health.body?.app);
    console.log('   API Status:', JSON.stringify(health.body?.apiStatus));
    if (health.status !== 200) throw new Error('Health check failed');

    console.log('\n1️⃣ Testing protected endpoints reject unauthenticated requests ...');
    const originalService = process.env.K_SERVICE;
    process.env.K_SERVICE = 'test';
    let rejectedStatus;
    try {
      await requireAuth(
        { headers: {} },
        {
          status(status) {
            rejectedStatus = status;
            return this;
          },
          json() {
            return this;
          },
        },
        () => {
          throw new Error('Protected middleware unexpectedly called next()');
        },
      );
    } finally {
      if (originalService === undefined) {
        delete process.env.K_SERVICE;
      } else {
        process.env.K_SERVICE = originalService;
      }
    }
    if (rejectedStatus !== 401) {
      throw new Error('Protected endpoint accepted an unauthenticated request');
    }

    // 2. Parse Intent
    console.log('\n2️⃣ Testing POST /api/parse-intent ...');
    const prompt = "hari ini mau ke Semarang, budget 100rb, suka tempat kuliner dan sejarah";
    console.log(`   Prompt: "${prompt}"`);
    const parseRes = await request('POST', '/parse-intent', { query: prompt });
    console.log('   Status:', parseRes.status);
    console.log('   Extracted Intent:', JSON.stringify(parseRes.body?.data, null, 2));
    if (parseRes.status !== 200 || !parseRes.body?.data?.location) {
      throw new Error('Intent parsing failed');
    }
    const intent = parseRes.body.data;

    // 3. Search Places
    console.log('\n3️⃣ Testing POST /api/search-places ...');
    const placesRes = await request('POST', '/search-places', intent);
    console.log('   Status:', placesRes.status);
    console.log(`   Found ${placesRes.body?.data?.length || 0} places.`);
    if (placesRes.body?.data?.length > 0) {
      console.log('   Sample place:', placesRes.body.data[0].name, `(${placesRes.body.data[0].category})`);
    }
    if (placesRes.status !== 200 || !placesRes.body?.data || placesRes.body.data.length === 0) {
      throw new Error('Search places failed');
    }
    const places = placesRes.body.data.slice(0, 4);

    // 4. Build Itinerary
    console.log('\n4️⃣ Testing POST /api/build-itinerary ...');
    const buildRes = await request('POST', '/build-itinerary', { places, intent });
    console.log('   Status:', buildRes.status);
    console.log('   Trip Title:', buildRes.body?.data?.title);
    console.log('   Total Travel Time:', buildRes.body?.data?.totalEstimatedTravelMinutes, 'minutes');
    console.log('   Stops Count:', buildRes.body?.data?.places?.length);
    if (buildRes.body?.data?.places) {
      buildRes.body.data.places.forEach((p, idx) => {
        console.log(`     [Stop ${idx + 1}] ${p.name} | Tiba: ${p.suggestedArrivalTime} (${p.suggestedDurationMinutes} mnt) | Jarak/waktu dari prev: ${p.estimatedTravelTimeFromPrevious || 0} mnt`);
      });
    }
    if (buildRes.status !== 200 || !buildRes.body?.data?.places) {
      throw new Error('Build itinerary failed');
    }

    console.log('\n5️⃣ Testing itinerary persistence and sharing ...');
    const savedRes = await request('POST', '/itineraries', {
      ...buildRes.body.data,
      shareCode: 'KLN-000001',
    });
    if (
      savedRes.status !== 200 ||
      !savedRes.body?.data?.shareCode ||
      savedRes.body.data.shareCode === 'KLN-000001'
    ) {
      throw new Error('Saving an itinerary failed');
    }
    const updatedRes = await request('POST', '/itineraries', {
      ...savedRes.body.data,
      shareCode: 'KLN-000002',
    });
    if (updatedRes.body?.data?.shareCode !== savedRes.body.data.shareCode) {
      throw new Error('Updating an itinerary changed its share code');
    }
    const savedList = await request('GET', '/itineraries');
    if (!savedList.body?.data?.some((item) => item.id === savedRes.body.data.id)) {
      throw new Error('Saved itinerary was not returned in the list');
    }
    const sharedRes = await request('GET', `/share/${savedRes.body.data.shareCode}`);
    if (sharedRes.status !== 200 || sharedRes.body?.data?.id !== savedRes.body.data.id) {
      throw new Error('Shared itinerary could not be retrieved');
    }
    const deletedRes = await request('DELETE', `/itineraries/${savedRes.body.data.id}`);
    if (deletedRes.status !== 200 || deletedRes.body?.success !== true) {
      throw new Error('Deleting an itinerary failed');
    }

    console.log('\n🎉 ALL TESTS PASSED SUCCESSFULLY! ✅');
  } catch (err) {
    console.error('\n❌ Test execution failed:', err.message);
    process.exit(1);
  }
}

runTests();
