import { Router } from 'express';
import { Location } from '../models';

export const location = Router();

location.post('/create', async (req, res) => {
  const { lat, long } = req.body;
  const loc = new Location({ lat, long });
  await loc.save();
  res.status(200).send('Success');
});

location.get('/getholes', async (req, res) => {
  try {
    let holes = await Location.find();

    res.json({ holes: holes.map((d: any) => ({ lat: d.lat, long: d.long })) });
  } catch (err) {
    res.json({ success: false, err });
  }
});
