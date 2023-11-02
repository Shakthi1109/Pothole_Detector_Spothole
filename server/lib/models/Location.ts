import { Schema, model } from 'mongoose';

const LocationSchema = new Schema({
  lat: Number,
  long: Number
});

export const Location = model('Location', LocationSchema);
