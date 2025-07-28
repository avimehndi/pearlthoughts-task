module.exports = ({ env }) => ({
  connection: {
    client: 'sqlite',
    connection: {
      filename: '/app/data.db',
    },
    useNullAsDefault: true,
  },
});
