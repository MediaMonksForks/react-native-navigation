import React, { Component } from 'react';
import { View } from 'react-native';
import PropTypes from 'prop-types';

export default class SharedElementTransition extends Component {
  static propTypes = {
    children: PropTypes.object,
  };

  render() {
    const { children, ...restProps } = this.props;
    return <View {...restProps}>{children}</View>;
  }
}
