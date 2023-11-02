import { location } from './api';
import express from 'express';
import mongoose from 'mongoose';

const app = express();

const port = 5000;
const dburl = 'mongodb://admin:admin123@ds263248.mlab.com:63248/spothole';
// Body parser
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use('/api/location', location);

mongoose.Promise = require('bluebird');
mongoose
  .connect(dburl, {
    promiseLibrary: require('bluebird'),
    useNewUrlParser: true
  })
  .then(() => console.log('connection succesful'))
  .catch((err: any) => console.error(err));

// Listen on port 5000
app.listen(port, () => {
  console.log(`Server is booming on port 5000
Visit http://localhost:5000`);
});
